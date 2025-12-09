// lib/presentation/player/comments/widgets/comment_composer.dart

import 'package:flutter/material.dart';

class CommentComposer extends StatefulWidget {
  final String hintText;
  final bool isSending;
  final Future<bool> Function(String text) onSend; // return true if success

  const CommentComposer({
    super.key,
    required this.hintText,
    required this.isSending,
    required this.onSend,
  });

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    final ok = await widget.onSend(text);
    if (ok && mounted) {
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi bình luận')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi bình luận. Vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            minLines: 1,
            maxLines: 3,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: widget.isSending ? null : _submit,
          icon: widget.isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
        )
      ],
    );
  }
}

