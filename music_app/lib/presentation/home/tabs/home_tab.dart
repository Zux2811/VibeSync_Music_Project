import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/sources/api_service.dart';
import '../../../data/sources/artist_service.dart';
import '../../../data/models/player_state_model.dart';
import '../../../data/models/artist_model.dart';
import '../../player/player_provider.dart';
import '../../auth/auth_provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _songs = [];
  List<Artist> _artists = [];
  int _page = 1;
  final int _limit = 20;
  bool _isLoading = false;
  bool _hasNext = true;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _loadArtists();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user == null && !auth.isFetchingUser) {
        auth.fetchUser();
      }
    });
    _scrollController.addListener(_onScroll);
    _scrollController.addListener(_onScrollForHeader);
  }

  void _onScrollForHeader() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> _loadArtists() async {
    try {
      final artists = await ArtistService.getArtists(limit: 10);
      if (mounted) {
        setState(() => _artists = artists);
      }
    } catch (e) {
      debugPrint('Error loading artists: $e');
    }
  }

  void _onScroll() {
    if (!_hasNext || _isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    try {
      final pageData = await ApiService.getSongsPage(
        page: _page,
        limit: _limit,
      );
      final items =
          (pageData['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _songs.clear();
        _songs.addAll(items);
        _hasNext = pageData['hasNext'] == true && items.isNotEmpty;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    try {
      _page += 1;
      final pageData = await ApiService.getSongsPage(
        page: _page,
        limit: _limit,
      );
      final items =
          (pageData['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _songs.addAll(items);
        _hasNext = pageData['hasNext'] == true && items.isNotEmpty;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Calculate header opacity based on scroll
    final headerOpacity = (_scrollOffset / 100).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          // Gradient background that fades on scroll
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  primaryColor.withOpacity(0.3 * (1 - headerOpacity)),
                  isDark ? AppColors.darkBg : AppColors.lightBg,
                ],
              ),
            ),
          ),

          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Modern Spotify-style App Bar
              SliverAppBar(
                expandedHeight: 80,
                floating: false,
                pinned: true,
                backgroundColor: (isDark ? AppColors.darkBg : AppColors.lightBg)
                    .withOpacity(headerOpacity),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                title: AnimatedOpacity(
                  opacity: headerOpacity,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _getGreeting(),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          // User Avatar
                          Builder(
                            builder: (context) {
                              final auth = context.watch<AuthProvider>();
                              final avatarUrl = auth.user?.avatarUrl;
                              final hasAvatar =
                                  avatarUrl != null && avatarUrl.isNotEmpty;
                              final name = auth.user?.name ?? 'V';

                              return GestureDetector(
                                onTap:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/settings',
                                    ),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor,
                                    image:
                                        hasAvatar
                                            ? DecorationImage(
                                              image: NetworkImage(avatarUrl!),
                                              fit: BoxFit.cover,
                                            )
                                            : null,
                                  ),
                                  child:
                                      hasAvatar
                                          ? null
                                          : Center(
                                            child: Text(
                                              name[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          // Greeting
                          Expanded(
                            child: Text(
                              _getGreeting(),
                              style: TextStyle(
                                color:
                                    isDark ? Colors.white : AppColors.textDark,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          // Notification & Settings
                          _buildIconButton(
                            icon: Icons.notifications_outlined,
                            onTap: () {},
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildIconButton(
                            icon: Icons.history,
                            onTap: () {},
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildIconButton(
                            icon: Icons.settings_outlined,
                            onTap:
                                () => Navigator.pushNamed(context, '/settings'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Quick Access Grid (Spotify style)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _buildQuickAccessGrid(isDark, primaryColor),
                ),
              ),

              // Featured Artists Section
              if (_artists.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                    child: _SectionTitle(title: "Popular Artists"),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _artists.length,
                      itemBuilder: (context, index) {
                        final artist = _artists[index];
                        return _ArtistCard(
                          artist: artist,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/artist/${artist.id}',
                              ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Recently Played / All Songs Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  child: _SectionTitle(title: "Made for you", onSeeAll: () {}),
                ),
              ),

              // Songs Grid - Responsive
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _buildSongsGrid(isDark, primaryColor),
              ),

              // Bottom spacing for mini player
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : AppColors.textDark,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(bool isDark, Color primaryColor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3.2,
      children: [
        _QuickAccessTile(
          title: 'Liked Songs',
          imageIcon: Icons.favorite,
          gradient: const LinearGradient(
            colors: [Color(0xFF5D4CF7), Color(0xFFB7A8FC)],
          ),
          onTap: () => Navigator.pushNamed(context, '/favorites'),
          isDark: isDark,
        ),
        _QuickAccessTile(
          title: 'Recently Played',
          imageIcon: Icons.history,
          onTap: () {},
          isDark: isDark,
        ),
        _QuickAccessTile(
          title: 'Top Mixes',
          imageIcon: Icons.auto_awesome,
          onTap: () {},
          isDark: isDark,
        ),
        _QuickAccessTile(
          title: 'Discover Weekly',
          imageIcon: Icons.explore,
          onTap: () {
            if (_songs.isNotEmpty) {
              final provider = context.read<PlayerProvider>();
              final playlist = _songs.map((m) => Song.fromJson(m)).toList();
              provider.setPlaylistAndPlay(playlist);
              Navigator.pushNamed(context, '/player');
            }
          },
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSongsGrid(bool isDark, Color primaryColor) {
    final responsive = Responsive(context);

    if (_songs.isEmpty && _isLoading) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: CircularProgressIndicator(color: primaryColor),
          ),
        ),
      );
    }

    if (_songs.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.music_off_rounded,
                  size: 64,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  'No songs available',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsive.gridColumns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: responsive.cardAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        if (_hasNext && index == _songs.length) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryColor,
            ),
          );
        }
        final songMap = _songs[index];
        final songObj = Song.fromJson(songMap);
        final playlist = _songs.map((m) => Song.fromJson(m)).toList();

        return _SongCard(
          title: songMap['title'] ?? 'Unknown',
          artist: songMap['artist'] ?? 'Unknown',
          imageUrl: songMap['imageUrl'],
          onTap: () {
            final provider = context.read<PlayerProvider>();
            provider.setPlaylistAndPlay(playlist, currentSong: songObj);
            Navigator.pushNamed(context, '/player');
          },
        );
      }, childCount: _songs.length + (_hasNext ? 1 : 0)),
    );
  }
}

// --- TÁCH CÁC WIDGET CON ---

// Widget cho tiêu đề mỗi mục
class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionTitle({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// Quick Access Tile - Spotify style compact tile
class _QuickAccessTile extends StatelessWidget {
  final String title;
  final IconData imageIcon;
  final LinearGradient? gradient;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickAccessTile({
    required this.title,
    required this.imageIcon,
    this.gradient,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgLighter : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Icon/Image container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                color:
                    gradient == null
                        ? (isDark
                            ? AppColors.darkCard
                            : AppColors.lightElevated)
                        : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
                boxShadow:
                    gradient != null
                        ? [
                          BoxShadow(
                            color: gradient!.colors.first.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(2, 0),
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                imageIcon,
                color:
                    gradient != null
                        ? Colors.white
                        : (isDark ? Colors.white70 : AppColors.textDark),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for Artist Card in horizontal list - Spotify style
class _ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback? onTap;

  const _ArtistCard({required this.artist, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgLighter : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar - Circular with shadow
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkCard : AppColors.lightElevated,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                image:
                    artist.avatarUrl != null
                        ? DecorationImage(
                          image: NetworkImage(artist.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  artist.avatarUrl == null
                      ? Center(
                        child: Text(
                          artist.displayName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark
                                    ? Colors.white54
                                    : AppColors.textDarkSecondary,
                          ),
                        ),
                      )
                      : null,
            ),
            const SizedBox(height: 12),
            // Name with verified badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    artist.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (artist.isVerified)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.verified,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Artist',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark
                        ? AppColors.textSecondary
                        : AppColors.textDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Song Card - Spotify style
class _SongCard extends StatefulWidget {
  final String title;
  final String artist;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _SongCard({
    required this.title,
    required this.artist,
    this.imageUrl,
    this.onTap,
  });

  @override
  State<_SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<_SongCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color:
                isDark
                    ? (_isHovered
                        ? AppColors.darkElevated
                        : AppColors.darkBgLighter)
                    : (_isHovered ? Colors.grey[100] : Colors.white),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with play button overlay
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color:
                            isDark
                                ? AppColors.darkCard
                                : AppColors.lightElevated,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image:
                            widget.imageUrl != null
                                ? DecorationImage(
                                  image: NetworkImage(widget.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          widget.imageUrl == null
                              ? Center(
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 40,
                                  color:
                                      isDark ? Colors.white24 : Colors.black26,
                                ),
                              )
                              : null,
                    ),
                    // Play button overlay - appears on hover
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isHovered ? 1.0 : 0.0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 200),
                          offset:
                              _isHovered ? Offset.zero : const Offset(0, 0.3),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Song info
              Text(
                widget.title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.artist,
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
      ),
    );
  }
}
