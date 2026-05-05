import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/app_database.dart';

part 'note_providers.g.dart';

// null = 全部，其他值 = 按类型筛选
final noteTypeFilterProvider = StateProvider<String?>((ref) => null);

@riverpod
Stream<List<Note>> allNotes(AllNotesRef ref) {
  final db = ref.watch(appDatabaseProvider);
  final filter = ref.watch(noteTypeFilterProvider);
  if (filter == null) {
    return db.watchAllNotes();
  }
  return db.watchNotesByType(filter);
}

@riverpod
Future<Note?> noteById(NoteByIdRef ref, int id) {
  final db = ref.watch(appDatabaseProvider);
  return db.getNoteById(id);
}

@riverpod
Stream<List<Reminder>> remindersForNote(RemindersForNoteRef ref, int noteId) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchRemindersForNote(noteId);
}

@riverpod
Stream<List<Reminder>> pendingReminders(PendingRemindersRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchPendingReminders();
}
