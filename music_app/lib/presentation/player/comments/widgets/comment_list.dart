// lib/presentation/player/comments/widgets/comment_list.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../comment_provider.dart';
import 'comment_item.dart';
import 'comment_composer.dart';
import '../../../../data/models/comment.dart';

class CommentsSection extends StatefulWidget {
  final int songId;
  const CommentsSection({super.key, required this.songId});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Load initial comments for the current song
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CommentProvider>().loadInitial(songId: widget.songId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) {
      context.read<CommentProvider>().loadInitial(songId: widget.songId);
      // Đợi frame gắn controller rồi mới jumpTo để tránh assert
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final provider = context.read<CommentProvider>();
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 48) {
      provider.loadMore(songId: widget.songId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommentProvider>(
      builder: (context, comments, _) {
        Widget listPart;
        if (comments.isInitialLoading) {
          listPart = const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (comments.items.isEmpty) {
          listPart = Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Chưa có bình luận',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        } else {
          // Build tree view: roots DESC, replies ASC
          final roots =
              comments.items.where((e) => e.parentId == null).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final Map<int, List<CommentModel>> children = {};
          for (final c in comments.items) {
            if (c.parentId != null) {
              children.putIfAbsent(c.parentId!, () => []).add(c);
            }
          }
          for (final list in children.values) {
            list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          }

          final List<Widget> tiles = [];
          for (final root in roots) {
            tiles.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: CommentItem(comment: root, rootId: root.id),
              ),
            );
            final replies = children[root.id] ?? const <CommentModel>[];
            for (final r in replies) {
              tiles.add(
                Padding(
                  padding: const EdgeInsets.only(left: 48.0, top: 4, bottom: 8),
                  child: CommentItem(comment: r, rootId: root.id),
                ),
              );
            }
          }

          listPart = Column(
            children: [
              SizedBox(
                height: 420,
                child: ListView(controller: _scroll, children: tiles),
              ),
              if (comments.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              if (!comments.hasMore && comments.items.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('— Hết bình luận —'),
                ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            CommentComposer(
              hintText: 'Viết bình luận...',
              isSending: comments.isPosting,
              onSend: (text) async {
                final ok = await comments.addComment(
                  songId: widget.songId,
                  content: text,
                );
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể kết nối. Vui lòng thử lại.'),
                    ),
                  );
                }
                return ok;
              },
            ),
            const SizedBox(height: 12),
            listPart,
          ],
        );
      },
    );
  }
}
