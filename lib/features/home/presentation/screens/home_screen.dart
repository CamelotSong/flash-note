import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/ai/ai_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/note_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(allNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('⚡', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('闪记'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () => context.go('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: _TypeFilterBar(),
        ),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (notes) => notes.isEmpty
            ? _EmptyState(onAdd: () => context.go('/record'))
            : _NoteList(notes: notes),
      ),
      floatingActionButton: _RecordFab(),
    );
  }
}

// ── 类型筛选栏（带数量角标）────────────────────────────────────

class _TypeFilterBar extends ConsumerWidget {
  const _TypeFilterBar();

  static const _filters = [
    (null, '全部', Icons.all_inclusive_outlined),
    ('voice', '语音', Icons.mic_outlined),
    ('meeting', '会议', Icons.groups_outlined),
    ('conversation', '对话', Icons.chat_outlined),
    ('text', '文字', Icons.edit_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(noteTypeFilterProvider);
    final countsAsync = ref.watch(noteCountByTypeProvider);
    final counts = countsAsync.valueOrNull ?? {};
    final totalCount = counts.values.fold(0, (a, b) => a + b);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _filters.map((f) {
          final isSelected = f.$1 == current;
          final count = f.$1 == null ? totalCount : (counts[f.$1] ?? 0);
          return GestureDetector(
            onTap: () => ref.read(noteTypeFilterProvider.notifier).state = f.$1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accent.withValues(alpha: 0.2)
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.accent : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(f.$3,
                      size: 14,
                      color: isSelected ? AppTheme.accent : AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(f.$2,
                      style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? AppTheme.accent : AppTheme.textSecondary)),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accent.withValues(alpha: 0.3)
                            : AppTheme.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$count',
                          style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? AppTheme.accent : AppTheme.textSecondary)),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 笔记列表 ──────────────────────────────────────────────────

class _NoteList extends ConsumerWidget {
  final List<Note> notes;
  const _NoteList({required this.notes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 按日期分组
    final groups = <String, List<Note>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final n in notes) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final String label;
      if (d == today) {
        label = '今天';
      } else if (d == yesterday) {
        label = '昨天';
      } else if (now.difference(d).inDays < 7) {
        label = '本周';
      } else {
        label = DateFormat('yyyy年MM月').format(d);
      }
      groups.putIfAbsent(label, () => []).add(n);
    }

    // 保持顺序：今天 > 昨天 > 本周 > 月份
    final orderedKeys = groups.keys.toList();

    final items = <Widget>[];
    for (final key in orderedKeys) {
      items.add(_DateGroupHeader(label: key, count: groups[key]!.length));
      for (final note in groups[key]!) {
        items.add(_NoteCard(note: note));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: items,
    );
  }
}

// ── 日期分组头 ────────────────────────────────────────────────

class _DateGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  const _DateGroupHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 6),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.textSecondary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeColor = AppTheme.typeColor(note.type);
    final fmt = DateFormat('MM-dd HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) async {
                final db = ref.read(appDatabaseProvider);
                await db.deleteNote(note.id);
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: '删除',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => context.go('/note/${note.id}'),
          onLongPress: () => _showContextMenu(context, ref),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: typeColor, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 类型标签 + 时间
                Row(
                  children: [
                    Icon(AppTheme.typeIcon(note.type), size: 14, color: typeColor),
                    const SizedBox(width: 4),
                    Text(AppTheme.typeLabel(note.type),
                        style: TextStyle(fontSize: 12, color: typeColor)),
                    const Spacer(),
                    Text(fmt.format(note.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    if (note.analyzed) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.auto_awesome, size: 12, color: AppTheme.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // 标题或摘要
                if (note.title?.isNotEmpty == true)
                  Text(note.title!,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                // 内容预览
                Text(
                  note.summary?.isNotEmpty == true ? note.summary! : note.content,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // 标签
                if (note.tags?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: note.tags!
                        .split(',')
                        .where((t) => t.isNotEmpty)
                        .take(4)
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('#$tag',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppTheme.accent)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _NoteContextMenu(note: note),
    );
  }
}

// ── 长按上下文菜单 ─────────────────────────────────────────────

class _NoteContextMenu extends ConsumerWidget {
  final Note note;
  const _NoteContextMenu({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽把手
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 笔记标题预览
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                note.title ?? note.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
            const Divider(height: 16),
            // 查看详情
            ListTile(
              leading: const Icon(Icons.open_in_new_outlined, color: AppTheme.accent),
              title: const Text('查看详情'),
              onTap: () {
                Navigator.pop(context);
                context.go('/note/${note.id}');
              },
            ),
            // AI 分析（未分析才显示）
            if (!note.analyzed)
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined, color: AppTheme.accent),
                title: const Text('AI 分析'),
                onTap: () async {
                  Navigator.pop(context);
                  final db = ref.read(appDatabaseProvider);
                  final aiService = ref.read(aiServiceProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI 分析中…'), duration: Duration(seconds: 2)),
                  );
                  try {
                    final analysis = await aiService.analyzeNote(note.content);
                    await db.updateNote(NotesCompanion(
                      id: Value(note.id),
                      analyzed: const Value(true),
                      summary: Value(analysis.summary),
                      tags: Value(analysis.tags.join(',')),
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ 分析完成'), backgroundColor: AppTheme.accent),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('分析失败: $e')),
                      );
                    }
                  }
                },
              ),
            // 复制内容
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: AppTheme.accent),
              title: const Text('复制内容'),
              onTap: () {
                Navigator.pop(context);
                final text = note.summary?.isNotEmpty == true
                    ? note.summary!
                    : note.content;
                // 使用 Clipboard
                _copyToClipboard(context, text);
              },
            ),
            // 设置提醒
            ListTile(
              leading: const Icon(Icons.alarm_add_outlined, color: AppTheme.accent),
              title: const Text('设置提醒'),
              onTap: () {
                Navigator.pop(context);
                context.go('/note/${note.id}');
                // 进入详情页后用户可操作，或后续做独立弹层
              },
            ),
            // 删除
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('删除', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.cardDark,
                    title: const Text('确认删除'),
                    content: const Text('删除后无法恢复，确定吗？'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('取消')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('删除',
                              style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  final db = ref.read(appDatabaseProvider);
                  await db.deleteNote(note.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }
}

// ── 录音 FAB（按住快速语音，点击进录音页）────────────────────

class _RecordFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 文字记录小按钮
        FloatingActionButton.small(
          heroTag: 'fab_text',
          backgroundColor: AppTheme.cardDark,
          child: const Icon(Icons.edit_outlined, color: AppTheme.accent),
          onPressed: () => _showQuickTextDialog(context),
        ),
        const SizedBox(height: 12),
        // 录音主按钮
        FloatingActionButton.extended(
          heroTag: 'fab_record',
          backgroundColor: AppTheme.recording,
          icon: const Icon(Icons.mic),
          label: const Text('录音'),
          onPressed: () => context.go('/record'),
        ),
      ],
    );
  }

  void _showQuickTextDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _QuickTextSheet(),
    );
  }
}

// ── 快速文字记录弹层 ──────────────────────────────────────────

class _QuickTextSheet extends ConsumerStatefulWidget {
  const _QuickTextSheet();

  @override
  ConsumerState<_QuickTextSheet> createState() => _QuickTextSheetState();
}

class _QuickTextSheetState extends ConsumerState<_QuickTextSheet> {
  final _ctrl = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _imagePaths = [];
  bool _saving = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _charCount = _ctrl.text.length));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('快速记录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              // 字数统计
              if (_charCount > 0)
                Text('$_charCount 字',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: _save,
                      child: const Text('保存',
                          style: TextStyle(color: AppTheme.accent)),
                    ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 5,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: '记录这一刻...',
              border: InputBorder.none,
            ),
          ),
          // 图片预览区
          if (_imagePaths.isNotEmpty) ...[
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imagePaths.length + (_imagePaths.length < 9 ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == _imagePaths.length) {
                    return _buildAddBtn();
                  }
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_imagePaths[i]),
                            width: 74, height: 74, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _imagePaths.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          Row(
            children: [
              if (_imagePaths.isEmpty)
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined,
                      color: AppTheme.textSecondary),
                  onPressed: _pickImages,
                  tooltip: '添加图片',
                ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddBtn() => GestureDetector(
        onTap: _pickImages,
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: AppTheme.textSecondary, size: 24),
        ),
      );

  Future<void> _pickImages() async {
    final status = await Permission.photos.request();
    if (status.isDenied || status.isPermanentlyDenied) return;
    final imgs = await _picker.pickMultiImage(imageQuality: 85, limit: 9);
    if (imgs.isNotEmpty) {
      setState(() {
        final rem = 9 - _imagePaths.length;
        _imagePaths.addAll(imgs.take(rem).map((x) => x.path));
      });
    }
  }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty && _imagePaths.isEmpty) return;
    setState(() => _saving = true);
    final content = _ctrl.text.trim().isEmpty ? '（图片记录）' : _ctrl.text.trim();
    final imagePathsJson = _imagePaths.isEmpty ? null : jsonEncode(_imagePaths);
    final db = ref.read(appDatabaseProvider);
    await db.insertNote(NotesCompanion.insert(
      content: content,
      imagePaths: Value(imagePathsJson),
    ));
    // 触觉反馈
    HapticFeedback.lightImpact();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

// ── 空状态 ────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('还没有任何记录',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          const Text('点击录音按钮，开始你的第一条闪记',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.mic),
            label: const Text('开始录音'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.recording,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
