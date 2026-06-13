import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  final bool embedded;
  const AiChatScreen({super.key, this.embedded = false});

  @override
  State<AiChatScreen> createState() => AiChatScreenState();
}

class AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <Map<String, String>>[];
  String? _sessionId;
  bool _loading = false;

  static const _suggestions = [
    'Explain photosynthesis simply',
    'Help me with algebra',
    'Create a study plan for exams',
    'Summarize World War II',
  ];

  void clearChat() {
    setState(() {
      _messages.clear();
      _sessionId = null;
      _loading = false;
    });
  }

  Future<void> _send([String? text]) async {
    final message = (text ?? _controller.text).trim();
    if (message.isEmpty || _loading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final api = context.read<AuthProvider>().api;
      final history = _messages.length > 1
          ? _messages
              .sublist(0, _messages.length - 1)
              .map((m) => {'role': m['role'] ?? 'user', 'content': m['content'] ?? ''})
              .toList()
          : <Map<String, String>>[];

      final result = await api.chat(message, sessionId: _sessionId, history: history);
      _sessionId = result['sessionId']?.toString();
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': result['reply']?.toString() ?? 'No response received.',
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Sorry, I could not respond. ${e.toString().replaceAll('Exception: ', '')}',
        });
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        children: [
          _ChatStatusBar(messageCount: _messages.length, loading: _loading),
          Expanded(child: _buildMessages()),
          if (_loading) _TypingIndicator(),
          _InputBar(controller: _controller, onSend: () => _send(), enabled: !_loading),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('AI Teacher'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add_comment_outlined), onPressed: clearChat, tooltip: 'New chat'),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          if (_loading) _TypingIndicator(),
          _InputBar(controller: _controller, onSend: () => _send(), enabled: !_loading),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) return _EmptyChat(onSuggestion: _send);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _ChatBubble(message: _messages[i]),
    );
  }
}

class _ChatStatusBar extends StatelessWidget {
  final int messageCount;
  final bool loading;

  const _ChatStatusBar({required this.messageCount, required this.loading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: loading ? AppColors.accent : const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            loading ? 'AI is thinking...' : 'MacallinAI Teacher · Online',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary),
          ),
          const Spacer(),
          if (messageCount > 0)
            Text('$messageCount messages', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final void Function(String) onSuggestion;
  const _EmptyChat({required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.15), const Color(0xFF7C3AED).withValues(alpha: 0.1)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('Your AI Teacher', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Ask anything — get step-by-step explanations tailored for you',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: AiChatScreenState._suggestions
                  .map((s) => ActionChip(
                        avatar: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        onPressed: () => onSuggestion(s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Thinking...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _InputBar({required this.controller, required this.onSend, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: 'Ask your AI teacher...',
                filled: true,
                fillColor: isDark ? AppColors.dark : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: enabled ? (_) => onSend() : null,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: enabled ? AppColors.primary : Colors.grey,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: enabled ? onSend : null,
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Map<String, String> message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(Icons.smart_toy_rounded, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : (isDark ? AppColors.darkSurface : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(
                message['content'] ?? '',
                style: TextStyle(color: isUser ? Colors.white : null, height: 1.5, fontSize: 14),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}
