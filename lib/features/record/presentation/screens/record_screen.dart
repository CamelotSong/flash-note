import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' show Value;
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen>
    with SingleTickerProviderStateMixin {
  // 录音类型
  String _type = 'voice'; // voice | meeting | conversation

  // 录音器
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;
  Duration _duration = Duration.zero;
  Timer? _timer;

  // 语音转文字
  final _stt = SpeechToText();
  bool _sttAvailable = false;
  String _liveText = '';
  final _allText = StringBuffer();

  // 图片
  final List<String> _imagePaths = [];
  final _picker = ImagePicker();

  // 动画
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _initStt();
  }

  Future<void> _initStt() async {
    final ok = await _stt.initialize(onError: (_) {});
    setState(() => _sttAvailable = ok);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    final mic = await Permission.microphone.request();
    return mic.isGranted;
  }

  Future<void> _startRecording() async {
    if (!await _requestPermissions()) {
      _showPermissionDenied();
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    _audioPath = '${dir.path}/rec_$ts.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: _audioPath!,
    );

    // 启动 STT 实时转写
    if (_sttAvailable) {
      _allText.clear();
      _stt.listen(
        onResult: (result) {
          setState(() {
            _liveText = result.recognizedWords;
            if (result.finalResult) {
              _allText.write('$_liveText ');
              _liveText = '';
            }
          });
        },
        listenFor: const Duration(hours: 2),
        pauseFor: const Duration(seconds: 4),
        localeId: 'zh_CN',
        cancelOnError: false,
        partialResults: true,
      );
    }

    _duration = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _duration += const Duration(seconds: 1));
    });

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    if (_sttAvailable) await _stt.stop();
    setState(() => _isRecording = false);
  }

  Future<void> _save() async {
    final transcript = '${_allText.toString()} $_liveText'.trim();
    final content = transcript.isNotEmpty ? transcript : '（录音，无转写文字）';
    final imagePathsJson = _imagePaths.isEmpty ? null : jsonEncode(_imagePaths);

    final db = ref.read(appDatabaseProvider);
    final id = await db.insertNote(NotesCompanion.insert(
      type: Value(_type),
      content: content,
      audioPath: Value(_audioPath),
      transcript: Value(transcript.isNotEmpty ? transcript : null),
      imagePaths: Value(imagePathsJson),
    ));

    if (mounted) context.go('/note/$id');
  }

  Future<void> _pickImages() async {
    final status = await Permission.photos.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('需要相册权限才能选择图片'),
            action: SnackBarAction(label: '去设置', onPressed: openAppSettings),
          ),
        );
      }
      return;
    }
    final images = await _picker.pickMultiImage(imageQuality: 85, limit: 9);
    if (images.isNotEmpty) {
      setState(() {
        final remaining = 9 - _imagePaths.length;
        _imagePaths.addAll(
          images.take(remaining).map((x) => x.path),
        );
      });
    }
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppTheme.textSecondary.withValues(alpha: 0.4), width: 1),
        ),
        child: const Icon(Icons.add_photo_alternate_outlined,
            color: AppTheme.textSecondary, size: 28),
      ),
    );
  }

  void _showPermissionDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('需要麦克风权限才能录音，请在设置中开启'),
        action: SnackBarAction(label: '去设置', onPressed: openAppSettings),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          if (_isRecording) await _stopRecording();
          if (context.mounted) {
            if (context.canPop()) context.pop();
            else context.go('/');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () async {
            if (_isRecording) await _stopRecording();
            if (mounted) {
              if (context.canPop()) context.pop();
              else context.go('/');
            }
          }),
          title: const Text('新建录音'),
          actions: [
            if (!_isRecording && _audioPath != null)
              TextButton(
                onPressed: _save,
                child: const Text('保存', style: TextStyle(color: AppTheme.accent)),
              ),
          ],
        ),
        body: Column(
          children: [
            // 类型选择
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _TypeSelector(
                selected: _type,
                onChanged: _isRecording ? null : (t) => setState(() => _type = t),
              ),
            ),

            // 录音主区域
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 计时器
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w200,
                        color: _isRecording ? AppTheme.recording : AppTheme.textSecondary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 录音按钮
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _isRecording ? _pulseAnim.value : 1.0,
                          child: child,
                        ),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording ? AppTheme.recording : AppTheme.accent,
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording ? AppTheme.recording : AppTheme.accent)
                                    .withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isRecording ? '点击停止录音' : (_audioPath != null ? '录音已完成' : '点击开始录音'),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // 实时转写文字区
            if (_isRecording || _allText.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      const Icon(Icons.text_fields, size: 14, color: AppTheme.accent),
                      const SizedBox(width: 6),
                      const Text('实时转写',
                          style: TextStyle(fontSize: 12, color: AppTheme.accent)),
                      const Spacer(),
                      if (!_sttAvailable)
                        const Text('（语音识别不可用）',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ]),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          '${_allText.toString()}$_liveText',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white, height: 1.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 底部操作
            if (!_isRecording && _audioPath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  children: [
                    // 图片选择区域
                    if (_imagePaths.isNotEmpty)
                      SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: _imagePaths.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            if (i == _imagePaths.length) {
                              return _imagePaths.length < 9
                                  ? _buildAddImageButton()
                                  : const SizedBox.shrink();
                            }
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_imagePaths[i]),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _imagePaths.removeAt(i)),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (_imagePaths.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined,
                              size: 18),
                          label: const Text('添加图片'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('保存笔记'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 类型选择器 ────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String>? onChanged;
  const _TypeSelector({required this.selected, this.onChanged});

  static const _types = [
    ('voice', '语音备忘'),
    ('meeting', '会议记录'),
    ('conversation', '对话记录'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _types.map((t) {
        final isSelected = selected == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged?.call(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.typeColor(t.$1).withValues(alpha: 0.2)
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.typeColor(t.$1)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(AppTheme.typeIcon(t.$1),
                      size: 20,
                      color: isSelected
                          ? AppTheme.typeColor(t.$1)
                          : AppTheme.textSecondary),
                  const SizedBox(height: 4),
                  Text(t.$2,
                      style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? AppTheme.typeColor(t.$1)
                              : AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
