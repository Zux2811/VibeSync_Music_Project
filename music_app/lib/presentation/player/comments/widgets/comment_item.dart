// lib/presentation/player/comments/widgets/comment_item.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/comment.dart';
import '../comment_provider.dart';
import 'comment_composer.dart';

class CommentItem extends StatefulWidget {
  final CommentModel comment;
  final int rootId; // đảm bảo reply luôn gắn vào bình luận gốc

  const CommentItem({super.key, required this.comment, required this.rootId});

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _showReply = false;

  Future<void> _reportDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final provider = context.read<CommentProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Báo cáo bình luận'),
            content: TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Nhập lý do...'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () async {
                  final msg = ctrl.text.trim();
                  if (msg.isEmpty) return;
                  final ok = await provider.report(
                    commentId: widget.comment.id,
                    message: msg,
                  );
                  if (mounted) Navigator.pop(ctx, ok);
                },
                child: const Text('Gửi'),
              ),
            ],
          ),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi báo cáo')));
    } else if (ok == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể kết nối. Vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    final created = DateFormat('dd/MM/yyyy HH:mm').format(c.createdAt);
    final provider = context.watch<CommentProvider>();
    final liking = provider.isLiking(c.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.user?.username ?? 'Người dùng',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        created,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(c.content),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed:
                            liking
                                ? null
                                : () async {
                                  final ok = await provider.like(c.id);
                                  if (!ok && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Không thể kết nối. Vui lòng thử lại.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        icon:
                            liking
                                ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(
                                  Icons.thumb_up_alt_outlined,
                                  size: 18,
                                ),
                        label: Text('${c.likes}'),
                      ),
                      TextButton(
                        onPressed:
                            () => setState(() => _showReply = !_showReply),
                        child: const Text('Trả lời'),
                      ),
                      TextButton(
                        onPressed: () => _reportDialog(context),
                        child: const Text('Báo cáo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_showReply)
          Padding(
            padding: const EdgeInsets.only(left: 48.0, top: 8, bottom: 8),
            child: CommentComposer(
              hintText: 'Trả lời bình luận...',
              isSending: provider.isPosting,
              onSend: (text) async {
                // luôn gắn parent_id = id của bình luận gốc
                final ok = await provider.addComment(
                  songId: c.songId ?? 0,
                  content: text,
                  parentId: widget.rootId,
                );
                if (ok) setState(() => _showReply = false);
                return ok;
              },
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}
