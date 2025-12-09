import 'package:music_app/data/models/player_state_model.dart';

class Playlist {
  final String id;
  String name;
  final List<Song> songs;
  String? imageUrl;

  Playlist({
    required this.id,
    required this.name,
    List<Song>? songs,
    this.imageUrl,
  }) : songs = songs ?? [];

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final idStr = (json['id'] ?? '').toString();
    // Backend may return 'songs' (alias) or 'Songs' (default)
    final rawSongs = (json['songs'] ?? json['Songs'] ?? []) as List;
    final songsList =
        rawSongs.isNotEmpty
            ? rawSongs.map((i) => Song.fromJson(i)).toList()
            : <Song>[];

    return Playlist(
      id: idStr,
      name: json['name'] ?? '',
      songs: songsList,
      imageUrl: json['imageUrl'],
    );
  }
}
