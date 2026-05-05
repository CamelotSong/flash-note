import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'tables.dart';

part 'app_database.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@DriftDatabase(tables: [Notes, Reminders, AiChats, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(notes, notes.imagePaths);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'flash_note_db');
  }

  // ── Notes ──────────────────────────────────────────────────

  Stream<List<Note>> watchAllNotes() =>
      (select(notes)..orderBy([(n) => OrderingTerm.desc(n.createdAt)])).watch();

  Stream<List<Note>> watchNotesByType(String type) => (select(notes)
        ..where((n) => n.type.equals(type))
        ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
      .watch();

  /// 各类型笔记数量：{'voice': 3, 'text': 12, ...}
  Stream<Map<String, int>> watchNoteCountByType() {
    return watchAllNotes().map((list) {
      final counts = <String, int>{};
      for (final n in list) {
        counts[n.type] = (counts[n.type] ?? 0) + 1;
      }
      return counts;
    });
  }

  Future<List<Note>> searchNotes(String query) => (select(notes)
        ..where((n) =>
            n.content.contains(query) |
            n.title.contains(query) |
            n.transcript.contains(query) |
            n.summary.contains(query))
        ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
      .get();

  Future<Note?> getNoteById(int id) =>
      (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();

  Future<int> insertNote(NotesCompanion note) =>
      into(notes).insert(note);

  Future<void> updateNote(NotesCompanion note) =>
      (update(notes)..where((n) => n.id.equals(note.id.value))).write(note);

  Future<void> deleteNote(int id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();

  // ── Reminders ─────────────────────────────────────────────

  Stream<List<Reminder>> watchRemindersForNote(int noteId) =>
      (select(reminders)..where((r) => r.noteId.equals(noteId))).watch();

  Stream<List<Reminder>> watchPendingReminders() =>
      (select(reminders)
            ..where((r) => r.status.equals('pending') & r.enabled.equals(true))
            ..orderBy([(r) => OrderingTerm.asc(r.remindAt)]))
          .watch();

  Future<int> insertReminder(RemindersCompanion reminder) =>
      into(reminders).insert(reminder);

  Future<Reminder?> getReminderById(int id) =>
      (select(reminders)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<void> updateReminder(RemindersCompanion reminder) =>
      (update(reminders)..where((r) => r.id.equals(reminder.id.value)))
          .write(reminder);

  Future<void> deleteReminder(int id) =>
      (delete(reminders)..where((r) => r.id.equals(id))).go();

  // ── AiChats ───────────────────────────────────────────────

  Future<List<AiChat>> getChatsForNote(int? noteId) {
    final q = select(aiChats);
    if (noteId != null) {
      q.where((c) => c.noteId.equals(noteId));
    } else {
      q.where((c) => c.noteId.isNull());
    }
    q.orderBy([(c) => OrderingTerm.asc(c.createdAt)]);
    return q.get();
  }

  Future<int> insertChat(AiChatsCompanion chat) =>
      into(aiChats).insert(chat);

  // ── Settings ──────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value));
}
