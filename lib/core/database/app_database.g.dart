// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'appDatabase_generated_hash_v1';

/// See also [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppDatabaseRef = ProviderRef<AppDatabase>;

// **************************************************************************
// DriftDatabaseGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Note {
  final int id;
  final String? title;
  final String content;
  final String type;
  final String? audioPath;
  final String? transcript;
  final String? summary;
  final String? tags;
  final bool analyzed;
  final String? imagePaths;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Note({
    required this.id,
    this.title,
    required this.content,
    required this.type,
    this.audioPath,
    this.transcript,
    this.summary,
    this.tags,
    required this.analyzed,
    this.imagePaths,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    throw UnimplementedError();
  }

  factory Note._fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Note(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      title: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}title']),
      content: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content'])!,
      type: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}type'])!,
      audioPath: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}audio_path']),
      transcript: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}transcript']),
      summary: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}summary']),
      tags: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}tags']),
      analyzed: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}analyzed'])!,
      imagePaths: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}image_paths']),
      createdAt: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at'])!,
      updatedAt: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}updated_at'])!,
    );
  }

  Note copyWith({
    int? id,
    Value<String?> title = const Value.absent(),
    String? content,
    String? type,
    Value<String?> audioPath = const Value.absent(),
    Value<String?> transcript = const Value.absent(),
    Value<String?> summary = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    bool? analyzed,
    Value<String?> imagePaths = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Note(
        id: id ?? this.id,
        title: title.present ? title.value : this.title,
        content: content ?? this.content,
        type: type ?? this.type,
        audioPath: audioPath.present ? audioPath.value : this.audioPath,
        transcript: transcript.present ? transcript.value : this.transcript,
        summary: summary.present ? summary.value : this.summary,
        tags: tags.present ? tags.value : this.tags,
        analyzed: analyzed ?? this.analyzed,
        imagePaths: imagePaths.present ? imagePaths.value : this.imagePaths,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('audioPath: $audioPath, ')
          ..write('transcript: $transcript, ')
          ..write('summary: $summary, ')
          ..write('tags: $tags, ')
          ..write('analyzed: $analyzed, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, content, type, audioPath,
      transcript, summary, tags, analyzed, imagePaths, createdAt, updatedAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.type == this.type &&
          other.audioPath == this.audioPath &&
          other.transcript == this.transcript &&
          other.summary == this.summary &&
          other.tags == this.tags &&
          other.analyzed == this.analyzed &&
          other.imagePaths == this.imagePaths &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String?> title;
  final Value<String> content;
  final Value<String> type;
  final Value<String?> audioPath;
  final Value<String?> transcript;
  final Value<String?> summary;
  final Value<String?> tags;
  final Value<bool> analyzed;
  final Value<String?> imagePaths;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.type = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.transcript = const Value.absent(),
    this.summary = const Value.absent(),
    this.tags = const Value.absent(),
    this.analyzed = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    required String content,
    this.type = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.transcript = const Value.absent(),
    this.summary = const Value.absent(),
    this.tags = const Value.absent(),
    this.analyzed = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : content = Value(content);

  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? type,
    Expression<String>? audioPath,
    Expression<String>? transcript,
    Expression<String>? summary,
    Expression<String>? tags,
    Expression<bool>? analyzed,
    Expression<String>? imagePaths,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (type != null) 'type': type,
      if (audioPath != null) 'audio_path': audioPath,
      if (transcript != null) 'transcript': transcript,
      if (summary != null) 'summary': summary,
      if (tags != null) 'tags': tags,
      if (analyzed != null) 'analyzed': analyzed,
      if (imagePaths != null) 'image_paths': imagePaths,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<String?>? title,
    Value<String>? content,
    Value<String>? type,
    Value<String?>? audioPath,
    Value<String?>? transcript,
    Value<String?>? summary,
    Value<String?>? tags,
    Value<bool>? analyzed,
    Value<String?>? imagePaths,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      audioPath: audioPath ?? this.audioPath,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      tags: tags ?? this.tags,
      analyzed: analyzed ?? this.analyzed,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<int>(id.value);
    if (title.present) map['title'] = Variable<String?>(title.value);
    if (content.present) map['content'] = Variable<String>(content.value);
    if (type.present) map['type'] = Variable<String>(type.value);
    if (audioPath.present) map['audio_path'] = Variable<String?>(audioPath.value);
    if (transcript.present) map['transcript'] = Variable<String?>(transcript.value);
    if (summary.present) map['summary'] = Variable<String?>(summary.value);
    if (tags.present) map['tags'] = Variable<String?>(tags.value);
    if (analyzed.present) map['analyzed'] = Variable<bool>(analyzed.value);
    if (imagePaths.present) map['image_paths'] = Variable<String?>(imagePaths.value);
    if (createdAt.present) map['created_at'] = Variable<DateTime>(createdAt.value);
    if (updatedAt.present) map['updated_at'] = Variable<DateTime>(updatedAt.value);
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('audioPath: $audioPath, ')
          ..write('transcript: $transcript, ')
          ..write('summary: $summary, ')
          ..write('tags: $tags, ')
          ..write('analyzed: $analyzed, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class Reminder {
  final int id;
  final int noteId;
  final String title;
  final String? description;
  final DateTime remindAt;
  final String status;
  final bool enabled;
  final DateTime createdAt;
  const Reminder({
    required this.id,
    required this.noteId,
    required this.title,
    this.description,
    required this.remindAt,
    required this.status,
    required this.enabled,
    required this.createdAt,
  });

  Reminder copyWith({
    int? id,
    int? noteId,
    String? title,
    Value<String?> description = const Value.absent(),
    DateTime? remindAt,
    String? status,
    bool? enabled,
    DateTime? createdAt,
  }) =>
      Reminder(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        remindAt: remindAt ?? this.remindAt,
        status: status ?? this.status,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('remindAt: $remindAt, ')
          ..write('status: $status, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, noteId, title, description, remindAt, status, enabled, createdAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.title == this.title &&
          other.description == this.description &&
          other.remindAt == this.remindAt &&
          other.status == this.status &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<int> noteId;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> remindAt;
  final Value<String> status;
  final Value<bool> enabled;
  final Value<DateTime> createdAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.status = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required int noteId,
    required String title,
    this.description = const Value.absent(),
    required DateTime remindAt,
    this.status = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : noteId = Value(noteId),
        title = Value(title),
        remindAt = Value(remindAt);

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? noteId,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime>? remindAt,
    Value<String>? status,
    Value<bool>? enabled,
    Value<DateTime>? createdAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      description: description ?? this.description,
      remindAt: remindAt ?? this.remindAt,
      status: status ?? this.status,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<int>(id.value);
    if (noteId.present) map['note_id'] = Variable<int>(noteId.value);
    if (title.present) map['title'] = Variable<String>(title.value);
    if (description.present) map['description'] = Variable<String?>(description.value);
    if (remindAt.present) map['remind_at'] = Variable<DateTime>(remindAt.value);
    if (status.present) map['status'] = Variable<String>(status.value);
    if (enabled.present) map['enabled'] = Variable<bool>(enabled.value);
    if (createdAt.present) map['created_at'] = Variable<DateTime>(createdAt.value);
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('remindAt: $remindAt, ')
          ..write('status: $status, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class AiChat {
  final int id;
  final int? noteId;
  final String role;
  final String content;
  final DateTime createdAt;
  const AiChat({
    required this.id,
    this.noteId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  AiChat copyWith({
    int? id,
    Value<int?> noteId = const Value.absent(),
    String? role,
    String? content,
    DateTime? createdAt,
  }) =>
      AiChat(
        id: id ?? this.id,
        noteId: noteId.present ? noteId.value : this.noteId,
        role: role ?? this.role,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() {
    return (StringBuffer('AiChat(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, noteId, role, content, createdAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiChat &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class AiChatsCompanion extends UpdateCompanion<AiChat> {
  final Value<int> id;
  final Value<int?> noteId;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  const AiChatsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AiChatsCompanion.insert({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    required String role,
    required String content,
    this.createdAt = const Value.absent(),
  })  : role = Value(role),
        content = Value(content);

  AiChatsCompanion copyWith({
    Value<int>? id,
    Value<int?>? noteId,
    Value<String>? role,
    Value<String>? content,
    Value<DateTime>? createdAt,
  }) {
    return AiChatsCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<int>(id.value);
    if (noteId.present) map['note_id'] = Variable<int?>(noteId.value);
    if (role.present) map['role'] = Variable<String>(role.value);
    if (content.present) map['content'] = Variable<String>(content.value);
    if (createdAt.present) map['created_at'] = Variable<DateTime>(createdAt.value);
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiChatsCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class AppSetting {
  final int id;
  final String key;
  final String value;
  const AppSetting({
    required this.id,
    required this.key,
    required this.value,
  });

  AppSetting copyWith({
    int? id,
    String? key,
    String? value,
  }) =>
      AppSetting(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
      );

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
  })  : key = Value(key),
        value = Value(value);

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? value,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<int>(id.value);
    if (key.present) map['key'] = Variable<String>(key.value);
    if (value.present) map['value'] = Variable<String>(value.value);
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final Notes notes = Notes();
  late final Reminders reminders = Reminders();
  late final AiChats aiChats = AiChats();
  late final AppSettings appSettings = AppSettings();

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [notes, reminders, aiChats, appSettings];
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
