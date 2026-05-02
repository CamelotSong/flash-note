import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
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

// ── 笔记列表 ──────────────────────────────────────────────────

class _NoteList extends ConsumerWidget {
  final List<Note> notes;
  const _NoteList({required this.notes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: notes.length,
      itemBuilder: (context, i) => _NoteCard(note: notes[i]),
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
              TextButton(
                onPressed: _saving ? null : _save,
                child: const Text('保存', style: TextStyle(color: AppTheme.accent)),
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
