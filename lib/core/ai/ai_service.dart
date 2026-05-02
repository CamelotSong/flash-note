import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';

/// 支持 OpenAI 兼容接口（OpenAI / 通义千问 / DeepSeek / 本地 Ollama 等）
class AiService {
  final AppDatabase _db;

  AiService(this._db);

  Future<Map<String, String>> _getConfig() async {
    final baseUrl = await _db.getSetting('ai_base_url') ?? 'https://api.openai.com/v1';
    final apiKey = await _db.getSetting('ai_api_key') ?? '';
    final model = await _db.getSetting('ai_model') ?? 'gpt-4o-mini';
    return {'baseUrl': baseUrl, 'apiKey': apiKey, 'model': model};
  }

  Future<String> chat(List<Map<String, String>> messages) async {
    final cfg = await _getConfig();
    if (cfg['apiKey']!.isEmpty) throw Exception('请先在设置中配置 AI API Key');

    final resp = await http.post(
      Uri.parse('${cfg['baseUrl']}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${cfg['apiKey']}',
      },
      body: jsonEncode({
        'model': cfg['model'],
        'messages': messages,
        'temperature': 0.3,
      }),
    ).timeout(const Duration(seconds: 60));

    if (resp.statusCode != 200) {
      throw Exception('AI 请求失败 ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    return data['choices'][0]['message']['content'] as String;
  }

  /// 分析笔记：生成摘要 + 提取待办/提醒
  Future<NoteAnalysis> analyzeNote(String content) async {
    final prompt = '''
你是一个智能笔记助手。请分析以下内容，返回 JSON 格式结果：

内容：
$content

请返回如下 JSON（不要包含代码块标记）：
{
  "summary": "一段话摘要",
  "action_items": ["待办1", "待办2"],
  "reminders": [
    {"title": "提醒事项", "time_hint": "明天下午3点", "description": "背景说明"}
  ],
  "tags": ["标签1", "标签2"],
  "sentiment": "positive|neutral|negative"
}

如果某项没有内容，返回空数组或空字符串。
''';

    final result = await chat([
      {'role': 'system', 'content': '你是一个智能笔记助手，善于提取关键信息和行动项。'},
      {'role': 'user', 'content': prompt},
    ]);

    try {
      final json = jsonDecode(result) as Map<String, dynamic>;
      return NoteAnalysis.fromJson(json);
    } catch (_) {
      return NoteAnalysis(summary: result, actionItems: [], reminders: [], tags: [], sentiment: 'neutral');
    }
  }

  /// 会议记录整理
  Future<String> formatMeeting(String transcript) async {
    return chat([
      {'role': 'system', 'content': '你是会议记录整理助手，将转录文字整理成结构化的会议纪要。'},
      {
        'role': 'user',
        'content': '请将以下会议转录整理为会议纪要，包括：参与者（如能识别）、主要议题、决策事项、待办任务、下次会议安排。\n\n$transcript'
      },
    ]);
  }
}

class NoteAnalysis {
  final String summary;
  final List<String> actionItems;
  final List<ReminderHint> reminders;
  final List<String> tags;
  final String sentiment;

  NoteAnalysis({
    required this.summary,
    required this.actionItems,
    required this.reminders,
    required this.tags,
    required this.sentiment,
  });

  factory NoteAnalysis.fromJson(Map<String, dynamic> json) {
    return NoteAnalysis(
      summary: json['summary'] as String? ?? '',
      actionItems: (json['action_items'] as List?)?.cast<String>() ?? [],
      reminders: (json['reminders'] as List?)
              ?.map((e) => ReminderHint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      sentiment: json['sentiment'] as String? ?? 'neutral',
    );
  }
}

class ReminderHint {
  final String title;
  final String timeHint;
  final String description;

  ReminderHint({required this.title, required this.timeHint, required this.description});

  factory ReminderHint.fromJson(Map<String, dynamic> json) => ReminderHint(
        title: json['title'] as String? ?? '',
        timeHint: json['time_hint'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}
