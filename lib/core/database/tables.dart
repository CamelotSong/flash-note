import 'package:drift/drift.dart';

// ── 笔记主表 ──────────────────────────────────────────────────

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get content => text()();
  // type: 'text' | 'voice' | 'meeting' | 'conversation'
  TextColumn get type => text().withDefault(const Constant('text'))();
  // 录音文件路径（voice/meeting/conversation 有值）
  TextColumn get audioPath => text().nullable()();
  // 转写文字
  TextColumn get transcript => text().nullable()();
  // AI 摘要
  TextColumn get summary => text().nullable()();
  // 标签（逗号分隔）
  TextColumn get tags => text().nullable()();
  // 是否已做 AI 分析
  BoolColumn get analyzed => boolean().withDefault(const Constant(false))();
  // 图片路径列表（JSON 数组字符串，如 '["path1","path2"]'）
  TextColumn get imagePaths => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── 提醒表 ────────────────────────────────────────────────────

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  // 关联笔记
  IntColumn get noteId => integer().references(Notes, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get remindAt => dateTime()();
  // status: 'pending' | 'done' | 'dismissed'
  TextColumn get status => text().withDefault(const Constant('pending'))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── AI 对话历史 ───────────────────────────────────────────────

class AiChats extends Table {
  IntColumn get id => integer().autoIncrement()();
  // 可选关联笔记，null 表示全局问答
  IntColumn get noteId => integer().references(Notes, #id).nullable()();
  // role: 'user' | 'assistant'
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── 用户设置 ──────────────────────────────────────────────────

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}
