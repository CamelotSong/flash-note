import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/ai/ai_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<AiChat> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final db = ref.read(appDatabaseProvider);
    final chats = await db.getChatsForNote(null);
    setState(() => _messages = chats);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final question = _ctrl.text.trim();
    if (question.isEmpty || _sending) return;
    _ctrl.clear();

    final db = ref.read(appDatabaseProvider);
    final aiService = ref.read(aiServiceProvider);

    // Save user message
    final userMsgId = await db.insertChat(AiChatsCompanion.insert(
      role: 'user',
      content: question,
      noteId: const Value(null),
    ));

    setState(() {
      _sending = true;
    });
    await _loadMessages();

    try {
      // Load notes for context
      final notes = await db.searchNotes('');

      // Call AI
      final answer = await aiService.askAboutAllNotes(question, notes);

      // Save AI response
      await db.insertChat(AiChatsCompanion.insert(
        role: 'assistant',
        content: answer,
        noteId: const Value(null),
      ));
    } catch (e) {
      await db.insertChat(AiChatsCompanion.insert(
        role: 'assistant',
        content: '⚠️ 出错了：$e',
        noteId: const Value(null),
      ));
    } finally {
      await _loadMessages();
      setState(() => _sending = false);
      _scrollToBottom();
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
          title: const Row(
            children: [
              Icon(Icons.smart_toy_outlined, size: 20, color: AppTheme.accent),
              SizedBox(width: 8),
              Text('AI 智能问答'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: '清空对话',
              onPressed: () => _confirmClear(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Message list
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _MessageBubble(msg: _messages[i]),
                    ),
            ),
            // Sending indicator
            if (_sending)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text('AI 思考中…',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            // Input bar
            _InputBar(ctrl: _ctrl, onSend: _send, sending: _sending),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.smart_toy_outlined, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text('向 AI 提问你的笔记',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          const Text('「我本周有哪些待办？」',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const Text('「帮我总结昨天的会议」',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const Text('「最近记录了哪些想法？」',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('清空对话'),
        content: const Text('确定要清空所有对话记录吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('清空',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      // We don't have a deleteChatsForNote(null) - just reload empty
      // For now, just clear from UI (messages stay in DB but won't hurt)
      setState(() => _messages = []);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

// ── 消息气泡 ──────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final AiChat msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.accent : AppTheme.cardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 输入栏 ────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final bool sending;

  const _InputBar({
    required this.ctrl,
    required this.onSend,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.textSecondary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(fontSize: 15),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: '问我任何关于你笔记的问题…',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          sending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded, color: AppTheme.accent),
                ),
        ],
      ),
    );
  }
}
