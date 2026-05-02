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

  @override
  Widget build(BuildContext context) {
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
            : _results.isEmpty && _ctrl.text.isNotEmpty
                ? const Center(
                    child: Text('没有找到相关记录',
                        style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final note = _results[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.typeColor(note.type).withValues(alpha: 0.2),
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
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        onTap: () => context.go('/note/${note.id}'),
                      );
                    },
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
