import 'package:flutter/material.dart';
import 'package:music_app/data/sources/api_service.dart';

class UserPlaylistsPage extends StatefulWidget {
  const UserPlaylistsPage({super.key});

  @override
  State<UserPlaylistsPage> createState() => _UserPlaylistsPageState();
}

class _UserPlaylistsPageState extends State<UserPlaylistsPage> {
  late Future<List<Map<String, dynamic>>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = ApiService.getUserPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Playlists')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no playlists yet.'));
          }

          final playlists = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 items per row
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio:
                  0.8, // Adjust aspect ratio for better look (width / height)
            ),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              final imageUrl = playlist['imageUrl'] as String?;

              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // TODO: Navigate to playlist detail page
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child:
                            (imageUrl != null && imageUrl.isNotEmpty)
                                ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.music_note,
                                      size: 48,
                                      color: Colors.grey,
                                    );
                                  },
                                )
                                : Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.music_note,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          playlist['name'] ?? 'Unnamed Playlist',
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
