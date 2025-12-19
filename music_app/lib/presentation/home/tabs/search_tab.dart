// lib/presentation/home/tabs/search_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/sources/api_service.dart';
import '../../../data/models/player_state_model.dart';
import '../../player/player_provider.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _allSongs = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadAllSongs();
    _focusNode.addListener(() {
      setState(() => _isSearching = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
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
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Search Header - Spotify style
            SliverToBoxAdapter(child: _buildHeader()),

            // Search Bar
            SliverToBoxAdapter(child: _buildSearchBar()),

            // Browse Categories (when not searching)
            if (!_isSearching && _searchController.text.isEmpty)
              SliverToBoxAdapter(child: _buildBrowseCategories()),

            // Content
            if (_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_searchController.text.isNotEmpty)
              _buildSearchResults()
            else
              _buildAllSongs(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseCategories() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      {
        'name': 'Pop',
        'color': const Color(0xFFE91E63),
        'icon': Icons.music_note,
      },
      {
        'name': 'Hip-Hop',
        'color': const Color(0xFFFF5722),
        'icon': Icons.headphones,
      },
      {
        'name': 'Rock',
        'color': const Color(0xFF9C27B0),
        'icon': Icons.electric_bolt,
      },
      {
        'name': 'Electronic',
        'color': const Color(0xFF00BCD4),
        'icon': Icons.graphic_eq,
      },
      {'name': 'Jazz', 'color': const Color(0xFF795548), 'icon': Icons.piano},
      {
        'name': 'Classical',
        'color': const Color(0xFF607D8B),
        'icon': Icons.library_music,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse all',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                decoration: BoxDecoration(
                  color: cat['color'] as Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Transform.rotate(
                        angle: 0.3,
                        child: Icon(
                          cat['icon'] as IconData,
                          size: 60,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        cat['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        'Search',
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textDark,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white : AppColors.lightElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _performSearch,
        style: TextStyle(
          color: isDark ? AppColors.textDark : AppColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'What do you want to listen to?',
          hintStyle: TextStyle(
            color: AppColors.textDarkSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.textDark, size: 24),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.close, color: AppColors.textDark),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_searchResults.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color:
                    isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(
                  color:
                      isDark ? Colors.white.withOpacity(0.5) : Colors.grey[700],
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching for something else',
                style: TextStyle(
                  color:
                      isDark ? Colors.white.withOpacity(0.3) : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final playlist = _searchResults.map((m) => Song.fromJson(m)).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_searchResults.length} results',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final songIndex = index - 1;
          if (songIndex >= _searchResults.length) return null;

          return _SongCard(
            song: _searchResults[songIndex],
            index: songIndex,
            onTap: () {
              final provider = context.read<PlayerProvider>();
              provider.setPlaylistAndPlay(
                playlist,
                currentSong: playlist[songIndex],
              );
              Navigator.pushNamed(context, '/player');
            },
          );
        }, childCount: _searchResults.length + 1),
      ),
    );
  }

  Widget _buildAllSongs() {
    final playlist = _allSongs.map((m) => Song.fromJson(m)).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryColor = Theme.of(context).colorScheme.primary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(Icons.music_note, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'All Songs',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final songIndex = index - 1;
          if (songIndex >= _allSongs.length) return null;

          return _SongCard(
            song: _allSongs[songIndex],
            index: songIndex,
            onTap: () {
              final provider = context.read<PlayerProvider>();
              provider.setPlaylistAndPlay(
                playlist,
                currentSong: playlist[songIndex],
              );
              Navigator.pushNamed(context, '/player');
            },
          );
        }, childCount: _allSongs.length + 1),
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  final Map<String, dynamic> song;
  final int index;
  final VoidCallback onTap;

  const _SongCard({
    required this.song,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [
            // Album Art
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Image.network(
                  song['imageUrl'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        color:
                            isDark
                                ? AppColors.darkCard
                                : AppColors.lightElevated,
                        child: Icon(
                          Icons.music_note,
                          color: isDark ? Colors.white24 : Colors.black26,
                          size: 24,
                        ),
                      ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song['title'] ?? 'Unknown',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song['artist'] ?? 'Unknown Artist',
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textSecondary
                              : AppColors.textDarkSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // More options
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color:
                    isDark
                        ? AppColors.textSecondary
                        : AppColors.textDarkSecondary,
                size: 20,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
