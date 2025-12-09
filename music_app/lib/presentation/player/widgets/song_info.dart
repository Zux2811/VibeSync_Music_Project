// lib/presentation/player/widgets/song_info.dart

import 'package:flutter/material.dart';
import '../../../data/models/player_state_model.dart';

class SongInfo extends StatelessWidget {
  final Song? song;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;

  const SongInfo({
    Key? key,
    required this.song,
    required this.isFavorite,
    required this.onFavoritePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (song == null) {
      return Center(
        child: Text(
          'No song selected',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return Column(
      children: [
        // Album Art
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: song!.imageUrl != null && song!.imageUrl!.isNotEmpty
              ? Image.network(
                  song!.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder();
                  },
                )
              : _buildPlaceholder(),
          ),
        ),
        const SizedBox(height: 32),

        // Song Title & Artist
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                song!.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                song!.artist,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              if (song!.album != null && song!.album!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Album: ${song!.album}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Favorite Button
        AnimatedScale(
          scale: isFavorite ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.cyan : Colors.grey[400],
              size: 32,
            ),
            onPressed: onFavoritePressed,
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 80,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

