// lib/data/models/comment.dart

class CommentUserRef {
  final int id;
  final String username;
  const CommentUserRef({required this.id, required this.username});

  factory CommentUserRef.fromJson(Map<String, dynamic> json) {
    return CommentUserRef(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      username: (json['username'] ?? 'Người dùng').toString(),
    );
  }
}

class CommentModel {
  final int id;
  final int userId;
  final int? songId;
  final int? playlistId;
  final int? parentId;
  final String content;
  final int likes;
  final DateTime createdAt;
  final CommentUserRef? user;

  const CommentModel({
    required this.id,
    required this.userId,
    this.songId,
    this.playlistId,
    this.parentId,
    required this.content,
    required this.likes,
    required this.createdAt,
    this.user,
  });

  bool get isRoot => parentId == null;

  CommentModel copyWith({
    int? likes,
  }) {
    return CommentModel(
      id: id,
      userId: userId,
      songId: songId,
      playlistId: playlistId,
      parentId: parentId,
      content: content,
      likes: likes ?? this.likes,
      createdAt: createdAt,
      user: user,
    );
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return CommentModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse('${json['user_id']}') ?? 0,
      songId: json['song_id'] == null
          ? null
          : (json['song_id'] is int
              ? json['song_id'] as int
              : int.tryParse('${json['song_id']}')),
      playlistId: json['playlist_id'] == null
          ? null
          : (json['playlist_id'] is int
              ? json['playlist_id'] as int
              : int.tryParse('${json['playlist_id']}')),
      parentId: json['parent_id'] == null
          ? null
          : (json['parent_id'] is int
              ? json['parent_id'] as int
              : int.tryParse('${json['parent_id']}')),
      content: (json['content'] ?? '').toString(),
      likes: json['likes'] is int ? json['likes'] as int : int.tryParse('${json['likes']}') ?? 0,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      user: (json['user'] is Map<String, dynamic>)
          ? CommentUserRef.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

