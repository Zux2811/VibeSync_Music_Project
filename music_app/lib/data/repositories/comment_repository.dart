// lib/data/repositories/comment_repository.dart

import 'package:music_app/data/models/comment.dart';
import 'package:music_app/data/sources/api_service.dart';

class CommentRepository {
  const CommentRepository();

  Future<List<CommentModel>> getComments({
    required int songId,
    int page = 1,
    int limit = 20,
  }) async {
    final raw = await ApiService.getComments(songId: songId, page: page, limit: limit);
    return raw.map((e) => CommentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CommentModel?> addComment({
    required int songId,
    required String content,
    int? parentId,
  }) async {
    final res = await ApiService.addComment(
      songId: songId,
      playlistId: null,
      content: content,
      parentId: parentId,
    );
    if (res.containsKey('comment') && res['comment'] is Map<String, dynamic>) {
      return CommentModel.fromJson(res['comment'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<int?> likeComment(int commentId) async {
    final res = await ApiService.likeComment(commentId);
    if (res.containsKey('likes')) {
      final v = res['likes'];
      if (v is int) return v;
      return int.tryParse('$v');
    }
    return null;
  }

  Future<bool> reportComment({required int commentId, required String message}) async {
    final res = await ApiService.reportComment(commentId: commentId, message: message);
    return (res['message'] as String?)?.isNotEmpty == true;
  }
}

