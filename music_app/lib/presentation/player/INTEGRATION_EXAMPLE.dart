// lib/presentation/player/INTEGRATION_EXAMPLE.dart
// This file shows how to integrate the Player into your app

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_provider.dart';
import 'player_page.dart';

// ============================================
// STEP 1: Update main.dart
// ============================================
/*
import 'package:provider/provider.dart';
import 'presentation/player/player_provider.dart';

void main() {
  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        // Add other providers here
      ],
      child: MaterialApp(
        title: 'Music App',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashPage(),
          '/signin_option': (context) => const SignInOptionPage(),
          '/signin': (context) => const SignInPage(),
          '/signup': (context) => const SignUpPage(),
          '/home': (context) => const HomePage(),
          '/player': (context) => const PlayerPage(),
        },
      ),
    );
  }
}
*/

// ============================================
// STEP 2: Navigate to Player from Home Page
// ============================================
class HomePageWithPlayer extends StatelessWidget {
  const HomePageWithPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Library')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PlayerPage(),
              ),
            );
          },
          child: const Text('Open Player'),
        ),
      ),
    );
  }
}

// ============================================
// STEP 3: Mini Player Widget (Optional)
// ============================================
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PlayerPage(),
              ),
            );
          },
          child: Container(
            color: Colors.grey[800],
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Album Art
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: song.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(song.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                    color: Colors.grey[700],
                  ),
                  child: song.imageUrl == null
                    ? const Icon(Icons.music_note)
                    : null,
                ),
                const SizedBox(width: 12),

                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

                // Play/Pause Button
                IconButton(
                  icon: Icon(
                    provider.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.cyan,
                  ),
                  onPressed: () => provider.togglePlayPause(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================
// STEP 4: Song List with Player Integration
// ============================================
class SongListWithPlayer extends StatelessWidget {
  final List<Map<String, dynamic>> songs;

  const SongListWithPlayer({
    Key? key,
    required this.songs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final isCurrentSong = provider.state.currentIndex == index;

            return ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: song['imageUrl'] != null
                    ? DecorationImage(
                        image: NetworkImage(song['imageUrl']),
                        fit: BoxFit.cover,
                      )
                    : null,
                  color: Colors.grey[700],
                ),
                child: song['imageUrl'] == null
                  ? const Icon(Icons.music_note)
                  : null,
              ),
              title: Text(
                song['title'],
                style: TextStyle(
                  color: isCurrentSong ? Colors.cyan : Colors.white,
                  fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                song['artist'],
                style: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
              trailing: isCurrentSong
                ? Icon(
                    provider.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.cyan,
                  )
                : null,
              onTap: () {
                provider.playTrackAtIndex(index);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlayerPage(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ============================================
// STEP 5: Accessing Player State in Widgets
// ============================================
class PlayerStatusWidget extends StatelessWidget {
  const PlayerStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Text('Current Song: ${provider.currentSong?.title ?? "None"}'),
            Text('Is Playing: ${provider.isPlaying}'),
            Text('Is Favorite: ${provider.isFavorite}'),
            Text('Repeat Mode: ${provider.repeatMode}'),
            Text('Shuffle: ${provider.isShuffle}'),
          ],
        );
      },
    );
  }
}

// ============================================
// STEP 6: API Integration Checklist
// ============================================
/*
TODO: Implement these endpoints in your backend:

1. GET /api/songs
   - Response: List of songs with id, title, artist, audioUrl, imageUrl, album

2. POST /api/favorites/:songId
   - Add song to user's favorites
   - Requires: Authorization header with JWT token

3. DELETE /api/favorites/:songId
   - Remove song from user's favorites
   - Requires: Authorization header with JWT token

4. GET /api/favorites
   - Get list of favorite song IDs
   - Requires: Authorization header with JWT token

5. POST /api/playlists/:playlistId/songs
   - Add song to playlist
   - Body: { songId: int }
   - Requires: Authorization header with JWT token

6. GET /api/playlists
   - Get user's playlists
   - Requires: Authorization header with JWT token

7. POST /api/playlists
   - Create new playlist
   - Body: { name: string }
   - Requires: Authorization header with JWT token

8. GET /api/artists/:artistName
   - Get artist information
   - Response: { name, bio, image, followers, songCount, albumCount }

Then uncomment the API calls in player_repository.dart
*/

