import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';

class ExportSection extends ConsumerWidget {
  const ExportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '📤 数据导出'),
        const SizedBox(height: 12),
        const Text(
          '将所有笔记导出为 TXT 或 JSON 文件，可分享或备份',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ExportButton(
                icon: Icons.text_snippet_outlined,
                label: '导出 TXT',
                color: AppTheme.accent,
                onTap: () => _export(context, ref, format: 'txt'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ExportButton(
                icon: Icons.data_object,
                label: '导出 JSON',
                color: AppTheme.success,
                onTap: () => _export(context, ref, format: 'json'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref, {
    required String format,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final notes = await db.searchNotes('');

    if (notes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有笔记可导出')),
        );
      }
      return;
    }

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'flash_note_export_$dateStr.$format';
    final file = File('${dir.path}/$fileName');

    if (format == 'txt') {
      final buf = StringBuffer();
      buf.writeln('闪记导出 — ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
      buf.writeln('共 ${notes.length} 条记录');
      buf.writeln('=' * 50);
      buf.writeln();
      for (final note in notes) {
        buf.writeln('【${_typeLabel(note.type)}】${DateFormat('yyyy-MM-dd HH:mm').format(note.createdAt)}');
        if (note.title?.isNotEmpty == true) buf.writeln('标题：${note.title}');
        buf.writeln('内容：${note.content}');
        if (note.transcript?.isNotEmpty == true) {
          buf.writeln('转写：${note.transcript}');
        }
        if (note.summary?.isNotEmpty == true) {
          buf.writeln('摘要：${note.summary}');
        }
        if (note.tags?.isNotEmpty == true) {
          buf.writeln('标签：${note.tags}');
        }
        buf.writeln('-' * 40);
        buf.writeln();
      }
      await file.writeAsString(buf.toString(), encoding: utf8);
    } else {
      final list = notes.map((n) => {
        'id': n.id,
        'type': n.type,
        'title': n.title,
        'content': n.content,
        'transcript': n.transcript,
        'summary': n.summary,
        'tags': n.tags,
        'audio_path': n.audioPath,
        'image_paths': n.imagePaths,
        'analyzed': n.analyzed,
        'created_at': n.createdAt.toIso8601String(),
        'updated_at': n.updatedAt.toIso8601String(),
      }).toList();
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(list),
        encoding: utf8,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导出到 ${file.path}'),
          action: SnackBarAction(
            label: '分享',
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  files: [XFile(file.path)],
                  text: '闪记笔记导出',
                ),
              );
            },
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'voice': return '语音';
      case 'meeting': return '会议';
      case 'conversation': return '对话';
      default: return '文字';
    }
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white));
}
