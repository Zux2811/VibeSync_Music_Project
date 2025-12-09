import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/sources/api_service.dart';
import '../../../data/models/player_state_model.dart';
import '../../player/player_provider.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allSongs = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSongs();
  }

  Future<void> _loadAllSongs() async {
    try {
      final songs = await ApiService.getSongs();
      setState(() {
        _allSongs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final results =
        _allSongs
            .where(
              (song) =>
                  (song['title'] ?? '').toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  (song['artist'] ?? '').toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();

    setState(() => _searchResults = results);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        title: Text(
          "Search",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _performSearch,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: "Search songs or artists...",
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white38 : Colors.black38,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white : Colors.black,
                    width: 2.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Search Results or All Songs
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_searchController.text.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "All Songs",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildSongsList(_allSongs),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Search Results (${_searchResults.length})",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_searchResults.isEmpty)
                    Center(
                      child: Text(
                        'No songs found',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    _buildSongsList(_searchResults),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList(List<Map<String, dynamic>> songs) {
    // Convert current list to Song objects once to reuse for queue
    final playlist = songs.map((m) => Song.fromJson(m)).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final songMap = songs[index];
        final songObj = Song.fromJson(songMap);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return _SongTile(
          song: songMap,
          isDark: isDark,
          onTap: () {
            // Set provider with selected song and full playlist, then navigate
            final provider = context.read<PlayerProvider>();
            provider.setPlaylistAndPlay(playlist, currentSong: songObj);
            Navigator.pushNamed(context, '/player');
          },
        );
      },
    );
  }
}

class _SongTile extends StatelessWidget {
  final Map<String, dynamic> song;
  final VoidCallback onTap;
  final bool isDark;

  const _SongTile({
    required this.song,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                song['imageUrl'] ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song['title'] ?? 'Unknown',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song['artist'] ?? 'Unknown Artist',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_outline,
              color: isDark ? Colors.white : Colors.black,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
