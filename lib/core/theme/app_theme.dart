import 'package:flutter/material.dart';

class AppTheme {
  // 主色：深墨蓝（专注感）
  static const Color primary = Color(0xFF1A2B4A);
  // 强调色：电光蓝
  static const Color accent = Color(0xFF4A90D9);
  // 录音中：活力橙红
  static const Color recording = Color(0xFFE55A2B);
  // 成功/提醒：翠绿
  static const Color success = Color(0xFF2ECC71);
  // 警告：金黄
  static const Color warning = Color(0xFFF39C12);
  // 背景：近黑
  static const Color bgDark = Color(0xFF0F1923);
  // 卡片背景
  static const Color cardDark = Color(0xFF1E2D42);
  // 次级文字
  static const Color textSecondary = Color(0xFF8899AA);

  // 笔记类型颜色
  static const Color typeText = Color(0xFF4A90D9);
  static const Color typeVoice = Color(0xFF9B59B6);
  static const Color typeMeeting = Color(0xFF2ECC71);
  static const Color typeConversation = Color(0xFFE67E22);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: accent,
          secondary: success,
          surface: cardDark,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: bgDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          color: cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textSecondary),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: cardDark,
          labelStyle: const TextStyle(fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: accent,
          secondary: success,
          surface: const Color(0xFFF5F7FA),
          onSurface: const Color(0xFF1A2B4A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF0F4F8),
          foregroundColor: Color(0xFF1A2B4A),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2B4A),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Color(0xFF8899AA)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF0F4F8),
          labelStyle: const TextStyle(fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  static Color typeColor(String type) {
    switch (type) {
      case 'voice': return typeVoice;
      case 'meeting': return typeMeeting;
      case 'conversation': return typeConversation;
      default: return typeText;
    }
  }

  static IconData typeIcon(String type) {
    switch (type) {
      case 'voice': return Icons.mic;
      case 'meeting': return Icons.groups_outlined;
      case 'conversation': return Icons.chat_outlined;
      default: return Icons.notes_outlined;
    }
  }

  static String typeLabel(String type) {
    switch (type) {
      case 'voice': return '语音';
      case 'meeting': return '会议';
      case 'conversation': return '对话';
      default: return '文字';
    }
  }
}
