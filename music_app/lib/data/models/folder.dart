import 'playlist.dart';

class Folder {
  final String id;
  String name;
  final List<Playlist> playlists;
  final List<Folder> subFolders;

  Folder({
    required this.id,
    required this.name,
    List<Playlist>? playlists,
    List<Folder>? subFolders,
  }) : playlists = playlists ?? [],
       subFolders = subFolders ?? [];

  factory Folder.fromJson(Map<String, dynamic> json) {
    // Handle both int and string IDs from backend
    final id = json['id'];
    final idStr = id is int ? id.toString() : (id ?? '').toString();

    // Playlists
    final rawPlaylists = (json['playlists'] ?? json['Playlists'] ?? []) as List;
    final playlistList =
        rawPlaylists.isNotEmpty
            ? rawPlaylists.map((i) => Playlist.fromJson(i)).toList()
            : <Playlist>[];

    // SubFolders (from Sequelize alias 'SubFolders' or custom 'subFolders')
    final rawSubs = (json['subFolders'] ?? json['SubFolders'] ?? []) as List;
    final subs =
        rawSubs.isNotEmpty
            ? rawSubs
                .map((i) => Folder.fromJson(i as Map<String, dynamic>))
                .toList()
            : <Folder>[];

    return Folder(
      id: idStr,
      name: json['name'] ?? '',
      playlists: playlistList,
      subFolders: subs,
    );
  }
}
