import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';

part 'note_providers.g.dart';

@riverpod
Stream<List<Note>> allNotes(AllNotesRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllNotes();
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
