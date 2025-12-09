import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/sources/api_service.dart';
import '../../../data/models/player_state_model.dart';
import '../../player/player_provider.dart';
import '../../auth/auth_provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _songs = [];
  int _page = 1;
  final int _limit = 20;
  bool _isLoading = false;
  bool _hasNext = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user == null && !auth.isFetchingUser) {
        auth.fetchUser();
      }
    });
    _scrollController.addListener(_onScroll);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            Builder(
              builder: (context) {
                final auth = context.watch<AuthProvider>();
                final avatarUrl = auth.user?.avatarUrl;
                final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                return CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
                  child:
                      hasAvatar
                          ? null
                          : Icon(
                            Icons.person,
                            size: 24,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                );
              },
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back !',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  'Music App',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Icon(
            Icons.bar_chart_rounded,
            color: Theme.of(context).iconTheme.color,
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.notifications_none,
            color: Theme.of(context).iconTheme.color,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),

            // === Phần 1: All Songs ===
            const _SectionTitle(title: "All Songs"),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child:
                  _songs.isEmpty && _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _songs.isEmpty
                      ? const Center(
                        child: Text(
                          'No songs available',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: _songs.length + (_hasNext ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_hasNext && index == _songs.length) {
                            // loader tail
                            return const SizedBox(
                              width: 80,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          final songMap = _songs[index];
                          final songObj = Song.fromJson(songMap);
                          final playlist =
                              _songs.map((m) => Song.fromJson(m)).toList();
                          return _SongCard(
                            title: songMap['title'] ?? 'Unknown',
                            artist: songMap['artist'] ?? 'Unknown',
                            imageUrl: songMap['imageUrl'],
                            onTap: () {
                              final provider = context.read<PlayerProvider>();
                              provider.setPlaylistAndPlay(
                                playlist,
                                currentSong: songObj,
                              );
                              Navigator.pushNamed(context, '/player');
                            },
                          );
                        },
                      ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// --- TÁCH CÁC WIDGET CON ---

// Widget cho tiêu đề mỗi mục
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

// Widget cho mục "Song Card"
class _SongCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1E1E1E),
          image:
              imageUrl != null
                  ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  artist,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
