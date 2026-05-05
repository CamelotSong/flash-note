import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ai/ai_service.dart';
import '../../../../core/reminder/reminder_service.dart';
import '../../../home/application/note_providers.dart';
import '../widgets/audio_player_widget.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final int noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteByIdProvider(widget.noteId));

    return noteAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('加载失败: $e'))),
      data: (note) {
        if (note == null) {
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.go('/')),
            ),
            body: const Center(child: Text('笔记不存在')),
          );
        }
        return _buildDetail(context, note);
      },
    );
  }

  Widget _buildDetail(BuildContext context, Note note) {
    final typeColor = AppTheme.typeColor(note.type);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) context.pop();
          else context.go('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () {
            if (context.canPop()) context.pop();
            else context.go('/');
          }),
          title: Row(children: [
            Icon(AppTheme.typeIcon(note.type), size: 16, color: typeColor),
            const SizedBox(width: 8),
            Text(AppTheme.typeLabel(note.type),
                style: TextStyle(color: typeColor, fontSize: 15)),
          ]),
          actions: [
            if (!note.analyzed && !_analyzing)
              TextButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('AI 分析'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                onPressed: () => _doAiAnalysis(note),
              ),
            if (_analyzing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
          bottom: TabBar(
            controller: _tabCtrl,
            indicatorColor: AppTheme.accent,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: '内容'),
              Tab(text: 'AI 分析'),
              Tab(text: '提醒'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _ContentTab(note: note),
            _AiTab(note: note),
            _RemindersTab(noteId: note.id),
          ],
        ),
      ),
    );
  }

  Future<void> _doAiAnalysis(Note note) async {
    setState(() => _analyzing = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final ai = AiService(db);

      final content = note.transcript ?? note.content;
      NoteAnalysis analysis;

      if (note.type == 'meeting') {
        final meetingStr = await ai.formatMeeting(content);
        analysis = NoteAnalysis(
          summary: meetingStr,
          actionItems: [],
          reminders: [],
          tags: ['会议'],
          sentiment: 'neutral',
        );
      } else {
        analysis = await ai.analyzeNote(content);
      }

      await db.updateNote(NotesCompanion(
        id: Value(note.id),
        summary: Value(analysis.summary),
        tags: Value(analysis.tags.join(',')),
        analyzed: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

      // 自动生成候选提醒
      final reminderSvc = ref.read(reminderServiceProvider);
      for (final hint in analysis.reminders) {
        final remindAt = reminderSvc.parseTimeHint(hint.timeHint);
        if (remindAt != null) {
          await db.insertReminder(RemindersCompanion.insert(
            noteId: note.id,
            title: hint.title,
            description: Value(hint.description),
            remindAt: remindAt,
            enabled: const Value(false), // 默认关闭，让用户确认
          ));
          // 保存到 DB 后 ID 是自增的，直接通过查询获取（这里简化，用 reminder ID）
          // reminder inserted, ID auto-assigned
        }
      }

      if (mounted) {
        _tabCtrl.animateTo(1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ AI 分析完成！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 分析失败: $e')),
        );
      }
    } finally {
      setState(() => _analyzing = false);
    }
  }
}

// ── 内容 Tab ──────────────────────────────────────────────────

class _ContentTab extends StatelessWidget {
  final Note note;
  const _ContentTab({required this.note});

  @override
  Widget build(BuildContext context) {
    final images = _parseImagePaths(note.imagePaths);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 时间
        Text(
          DateFormat('yyyy年MM月dd日 HH:mm').format(note.createdAt),
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        // 音频播放器
        if (note.audioPath != null) ...[
          const _SectionHeader(icon: Icons.graphic_eq, label: '录音'),
          const SizedBox(height: 8),
          AudioPlayerWidget(audioPath: note.audioPath!),
          const SizedBox(height: 16),
        ],
        // 转写或内容
        if (note.transcript?.isNotEmpty == true) ...[
          const _SectionHeader(icon: Icons.text_fields, label: '转写文字'),
          const SizedBox(height: 8),
          Text(note.transcript!,
              style: const TextStyle(fontSize: 15, height: 1.8, color: Colors.white)),
        ] else ...[
          Text(note.content,
              style: const TextStyle(fontSize: 15, height: 1.8, color: Colors.white)),
        ],
        // 图片列表
        if (images.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionHeader(icon: Icons.photo_library_outlined, label: '图片'),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _showImagePreview(context, images, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(images[i]),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<String> _parseImagePaths(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  void _showImagePreview(BuildContext context, List<String> paths, int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: index),
              itemCount: paths.length,
              itemBuilder: (_, i) => Center(
                child: InteractiveViewer(
                  child: Image.file(
                    File(paths[i]),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined,
                            color: Colors.white54, size: 64),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI 分析 Tab ───────────────────────────────────────────────

class _AiTab extends ConsumerWidget {
  final Note note;
  const _AiTab({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!note.analyzed || note.summary == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text('尚未进行 AI 分析',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            const Text('点击右上角「AI 分析」按钮',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    // 解析 action items（存在 summary 的 JSON 部分，或单独字段）
    final actionItems = _parseActionItems(note.summary!);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionHeader(icon: Icons.summarize_outlined, label: '摘要'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: MarkdownBody(
            data: note.summary!,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 14, height: 1.7, color: Colors.white),
              h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accent),
              listBullet: const TextStyle(color: AppTheme.accent),
            ),
          ),
        ),
        if (note.tags?.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          const _SectionHeader(icon: Icons.label_outline, label: '标签'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: note.tags!.split(',').where((t) => t.isNotEmpty).map((tag) =>
              Chip(
                label: Text('#$tag', style: const TextStyle(fontSize: 12, color: AppTheme.accent)),
                backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                side: BorderSide.none,
              )
            ).toList(),
          ),
        ],
        // ── 待办事项 ──
        if (actionItems.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionHeader(icon: Icons.checklist_outlined, label: '待办事项'),
          const SizedBox(height: 8),
          ...actionItems.map((item) => _ActionItemCard(item: item, noteId: note.id)),
        ],
      ],
    );
  }

  List<String> _parseActionItems(String summary) {
    // 从 markdown 里提取 "- [ ]" 或 "**待办**" 后的条目
    final lines = summary.split('\n');
    final items = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- [ ]') || trimmed.startsWith('* [ ]')) {
        items.add(trimmed.replaceFirst(RegExp(r'^[-*]\s*\[\s*\]\s*'), '').trim());
      } else if (trimmed.startsWith('- ') && 
                 (summary.contains('待办') || summary.contains('action') || summary.contains('Action'))) {
        // 在待办区块下的列表项
        final content = trimmed.substring(2).trim();
        if (content.isNotEmpty && content.length < 100) items.add(content);
      }
    }
    return items.take(10).toList();
  }
}

// ── 提醒 Tab ──────────────────────────────────────────────────

class _RemindersTab extends ConsumerWidget {
  final int noteId;
  const _RemindersTab({required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersForNoteProvider(noteId));

    return remindersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (reminders) => Column(
        children: [
          Expanded(
            child: reminders.isEmpty
                ? const Center(
                    child: Text('暂无提醒', style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reminders.length,
                    itemBuilder: (_, i) => _ReminderCard(reminder: reminders[i]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_alarm_outlined),
              label: const Text('手动添加提醒'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                minimumSize: const Size.fromHeight(46),
              ),
              onPressed: () => _showAddReminderDialog(context, ref, noteId),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context, WidgetRef ref, int noteId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddReminderSheet(noteId: noteId),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('MM月dd日 HH:mm');
    final svc = ref.read(reminderServiceProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reminder.enabled
              ? AppTheme.success.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            reminder.status == 'done' ? Icons.check_circle : Icons.alarm_outlined,
            color: reminder.enabled ? AppTheme.success : AppTheme.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: reminder.enabled ? Colors.white : AppTheme.textSecondary,
                      decoration: reminder.status == 'done'
                          ? TextDecoration.lineThrough
                          : null,
                    )),
                const SizedBox(height: 2),
                Text(fmt.format(reminder.remindAt),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: reminder.enabled,
            activeColor: AppTheme.success,
            onChanged: (_) => svc.toggleReminder(reminder),
          ),
        ],
      ),
    );
  }
}

class _AddReminderSheet extends ConsumerStatefulWidget {
  final int noteId;
  const _AddReminderSheet({required this.noteId});

  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _titleCtrl = TextEditingController();
  DateTime _remindAt = DateTime.now().add(const Duration(hours: 1));

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('添加提醒',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '提醒内容',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(fmt.format(_remindAt)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              minimumSize: const Size.fromHeight(46),
            ),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _remindAt,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date == null || !mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_remindAt),
              );
              if (time == null) return;
              setState(() => _remindAt =
                  DateTime(date.year, date.month, date.day, time.hour, time.minute));
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent, foregroundColor: Colors.white,
              ),
              onPressed: _save,
              child: const Text('保存提醒'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final db = ref.read(appDatabaseProvider);
    final svc = ref.read(reminderServiceProvider);
    final id = await db.insertReminder(RemindersCompanion.insert(
      noteId: widget.noteId,
      title: _titleCtrl.text.trim(),
      remindAt: _remindAt,
      enabled: const Value(true),
    ));
    // 调度通知
    final r = Reminder(
      id: id, noteId: widget.noteId, title: _titleCtrl.text.trim(),
      description: null, remindAt: _remindAt,
      status: 'pending', enabled: true, createdAt: DateTime.now(),
    );
    await svc.scheduleReminder(r);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppTheme.accent),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(
          fontSize: 13, color: AppTheme.accent, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ── 待办事项卡片（支持一键转提醒）────────────────────────────

class _ActionItemCard extends ConsumerWidget {
  final String item;
  final int noteId;
  const _ActionItemCard({required this.item, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_unchecked, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item,
                style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4)),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _setReminder(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Tooltip(
                message: '设为提醒',
                child: const Icon(Icons.alarm_add_outlined, size: 18, color: AppTheme.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setReminder(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: '选择提醒日期',
    );
    if (picked == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      helpText: '选择提醒时间',
    );
    if (time == null || !context.mounted) return;

    final scheduledAt = DateTime(
        picked.year, picked.month, picked.day, time.hour, time.minute);

    final db = ref.read(appDatabaseProvider);
    final reminderService = ref.read(reminderServiceProvider);

    final reminderId = await db.insertReminder(RemindersCompanion.insert(
      noteId: noteId,
      title: item,
      remindAt: scheduledAt,
    ));

    // 查回 Reminder 对象再调度
    final reminder = await db.getReminderById(reminderId);
    if (reminder != null) {
      await reminderService.scheduleReminder(reminder);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已设置提醒：${DateFormat('MM-dd HH:mm').format(scheduledAt)}'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }
}
