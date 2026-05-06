import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  List<Note> _results = [];
  bool _searching = false;
  List<MapEntry<String, int>> _tagCloud = [];

  @override
  void initState() {
    super.initState();
    _loadTagCloud();
    _ctrl.addListener(() {
      if (_ctrl.text.isEmpty) setState(() => _results = []);
    });
  }

  Future<void> _loadTagCloud() async {
    final db = ref.read(appDatabaseProvider);
    final notes = await db.searchNotes('');
    final counts = <String, int>{};
    for (final n in notes) {
      if (n.tags?.isNotEmpty == true) {
        for (final t in n.tags!.split(',')) {
          final tag = t.trim();
          if (tag.isNotEmpty) counts[tag] = (counts[tag] ?? 0) + 1;
        }
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (mounted) {
      setState(() => _tagCloud = sorted.take(20).toList());
    }
  }

  Color _tagColor(String tag) {
    // Choose a color from a palette based on tag hash
    const palette = [
      AppTheme.accent,
      AppTheme.success,
      AppTheme.typeVoice,
      AppTheme.typeConversation,
      AppTheme.warning,
      AppTheme.typeMeeting,
    ];
    return palette[tag.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final showTagCloud = _ctrl.text.isEmpty && _tagCloud.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/')),
          titleSpacing: 0,
          title: TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              hintText: '搜索笔记内容...',
              border: InputBorder.none,
              filled: false,
            ),
            onChanged: _onSearch,
          ),
          actions: [
            if (_ctrl.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _ctrl.clear();
                  setState(() => _results = []);
                },
              ),
          ],
        ),
        body: _searching
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 热门标签云（搜索框为空时显示）
                  if (showTagCloud)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('热门标签',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tagCloud
                                .map((e) => ActionChip(
                                      label: Text('#${e.key}  ${e.value}',
                                          style: const TextStyle(fontSize: 12)),
                                      backgroundColor: _tagColor(e.key)
                                          .withValues(alpha: 0.15),
                                      side: BorderSide(
                                          color: _tagColor(e.key)
                                              .withValues(alpha: 0.4)),
                                      labelStyle: TextStyle(
                                          color: _tagColor(e.key),
                                          fontSize: 12),
                                      onPressed: () {
                                        _ctrl.text = e.key;
                                        _onSearch(e.key);
                                      },
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  // 搜索结果
                  if (_results.isEmpty && _ctrl.text.isNotEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('没有找到相关记录',
                            style:
                                TextStyle(color: AppTheme.textSecondary)),
                      ),
                    )
                  else if (_results.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final note = _results[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.typeColor(note.type)
                                  .withValues(alpha: 0.2),
                              child: Icon(AppTheme.typeIcon(note.type),
                                  size: 18,
                                  color: AppTheme.typeColor(note.type)),
                            ),
                            title: Text(
                              note.title?.isNotEmpty == true
                                  ? note.title!
                                  : note.content.substring(
                                      0,
                                      note.content.length > 40
                                          ? 40
                                          : note.content.length),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              note.summary ?? note.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12),
                            ),
                            onTap: () => context.go('/note/${note.id}'),
                          );
                        },
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
      ),
    );
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final db = ref.read(appDatabaseProvider);
    final results = await db.searchNotes(query.trim());
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
