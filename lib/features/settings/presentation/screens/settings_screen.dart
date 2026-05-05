import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/export_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _baseUrlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  bool _showKey = false;
  bool _autoAnalyzeRecording = false;

  // 预设接入点
  static const _presets = [
    ('OpenAI', 'https://api.openai.com/v1', 'gpt-4o-mini'),
    ('通义千问', 'https://dashscope.aliyuncs.com/compatible-mode/v1', 'qwen-turbo'),
    ('DeepSeek', 'https://api.deepseek.com/v1', 'deepseek-chat'),
    ('本地 Ollama', 'http://localhost:11434/v1', 'llama3'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = ref.read(appDatabaseProvider);
    _baseUrlCtrl.text = await db.getSetting('ai_base_url') ?? 'https://api.openai.com/v1';
    _apiKeyCtrl.text = await db.getSetting('ai_api_key') ?? '';
    _modelCtrl.text = await db.getSetting('ai_model') ?? 'gpt-4o-mini';
    final autoAnalyze = await db.getSetting('auto_analyze_recording');
    setState(() {
      _autoAnalyzeRecording = autoAnalyze == 'true';
      _loaded = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final db = ref.read(appDatabaseProvider);
    await db.setSetting('ai_base_url', _baseUrlCtrl.text.trim());
    await db.setSetting('ai_api_key', _apiKeyCtrl.text.trim());
    await db.setSetting('ai_model', _modelCtrl.text.trim());
    await db.setSetting('auto_analyze_recording', _autoAnalyzeRecording ? 'true' : 'false');
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 设置已保存')),
      );
    }
  }

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
          title: const Text('设置'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中...' : '保存',
                  style: const TextStyle(color: AppTheme.accent)),
            ),
          ],
        ),
        body: _loaded
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // AI 配置
                  const _SectionTitle(title: '🤖 AI 配置'),
                  const SizedBox(height: 6),
                  const Text(
                    '支持任何 OpenAI 兼容接口（OpenAI / 通义千问 / DeepSeek / 本地 Ollama 等）',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // 快速预设
                  const Text('快速选择', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _presets.map((p) => ActionChip(
                      label: Text(p.$1, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppTheme.cardDark,
                      side: const BorderSide(color: AppTheme.accent, width: 0.5),
                      onPressed: () => setState(() {
                        _baseUrlCtrl.text = p.$2;
                        _modelCtrl.text = p.$3;
                      }),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _baseUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://api.openai.com/v1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyCtrl,
                    obscureText: !_showKey,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'sk-...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility,
                            size: 18),
                        onPressed: () => setState(() => _showKey = !_showKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(
                      labelText: '模型名称',
                      hintText: 'gpt-4o-mini',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 录音后自动分析开关
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      value: _autoAnalyzeRecording,
                      onChanged: (v) => setState(() => _autoAnalyzeRecording = v),
                      activeColor: AppTheme.accent,
                      title: const Text('录音完成后自动分析',
                          style: TextStyle(fontSize: 14, color: Colors.white)),
                      subtitle: const Text('保存录音后在后台静默生成摘要和标签',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 数据导出
                  const ExportSection(),

                  // 关于
                  const _SectionTitle(title: 'ℹ️ 关于'),
                  const SizedBox(height: 12),
                  const _AboutTile(label: 'App 名称', value: '闪记 FlashNote'),
                  const _AboutTile(label: '版本', value: '1.0.0'),
                  const _AboutTile(label: '数据存储', value: '本地 SQLite（无云端）'),
                  const _AboutTile(label: '语音识别', value: '本机离线（系统原生）'),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
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

class _AboutTile extends StatelessWidget {
  final String label;
  final String value;
  const _AboutTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const Spacer(),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      );
}
