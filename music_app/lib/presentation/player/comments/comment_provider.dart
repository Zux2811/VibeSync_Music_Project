// lib/presentation/player/comments/comment_provider.dart

import 'package:flutter/material.dart';
import 'package:music_app/data/models/comment.dart';
import 'package:music_app/data/repositories/comment_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentProvider extends ChangeNotifier {
  final CommentRepository _repo = const CommentRepository();

  final List<CommentModel> _items = [];
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool _initialLoading = false;
  bool _loadingMore = false;
  bool _posting = false;
  final Set<int> _liking = {};

  // Track last token to refresh comments after account switching
  String? _lastToken;

  List<CommentModel> get items => List.unmodifiable(_items);
  bool get isInitialLoading => _initialLoading;
  bool get isLoadingMore => _loadingMore;
  bool get isPosting => _posting;
  bool get hasMore => _hasMore;
  bool isLiking(int id) => _liking.contains(id);

  Future<bool> _refreshIfTokenChanged(int songId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != _lastToken) {
      _lastToken = token;
      // reset state and reload page 1
      _page = 1;
      _hasMore = true;
      _items.clear();
      _initialLoading = true;
      notifyListeners();
      try {
        final data = await _repo.getComments(
          songId: songId,
          page: _page,
          limit: _limit,
        );
        _items.addAll(data);
        _hasMore = data.length >= _limit;
      } catch (_) {
      } finally {
        _initialLoading = false;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<void> loadInitial({required int songId}) async {
    if (await _refreshIfTokenChanged(songId)) return;

    _page = 1;
    _hasMore = true;
    _initialLoading = true;
    _items.clear();
    notifyListeners();
    try {
      final data = await _repo.getComments(
        songId: songId,
        page: _page,
        limit: _limit,
      );
      _items.addAll(data);
      _hasMore = data.length >= _limit;
    } catch (_) {
      // swallow; UI should show snackbar on error outside
    } finally {
      _initialLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore({required int songId}) async {
    if (await _refreshIfTokenChanged(songId)) {
      return; // token changed → already reloaded page 1
    }

    if (!_hasMore || _loadingMore || _initialLoading) return;
    _loadingMore = true;
    _page += 1;
    notifyListeners();
    try {
      final data = await _repo.getComments(
        songId: songId,
        page: _page,
        limit: _limit,
      );
      _items.addAll(data);
      _hasMore = data.length >= _limit;
    } catch (_) {
      _page -= 1; // rollback
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> addComment({
    required int songId,
    required String content,
    int? parentId,
  }) async {
    if (_posting) return false;
    await _refreshIfTokenChanged(songId);
    _posting = true;
    notifyListeners();
    try {
      final created = await _repo.addComment(
        songId: songId,
        content: content,
        parentId: parentId,
      );
      if (created != null) {
        _items.insert(0, created); // show on top (backend sorts DESC)
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _posting = false;
      notifyListeners();
    }
  }

  Future<bool> like(int commentId) async {
    if (_liking.contains(commentId)) return false;
    _liking.add(commentId);
    notifyListeners();
    try {
      final newLikes = await _repo.likeComment(commentId);
      if (newLikes != null) {
        final i = _items.indexWhere((e) => e.id == commentId);
        if (i != -1) {
          _items[i] = _items[i].copyWith(likes: newLikes);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _liking.remove(commentId);
      notifyListeners();
    }
  }

  Future<bool> report({required int commentId, required String message}) async {
    try {
      return await _repo.reportComment(commentId: commentId, message: message);
    } catch (_) {
      return false;
    }
  }
}
