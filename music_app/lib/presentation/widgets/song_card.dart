import 'package:flutter/material.dart';
import '../../data/models/player_state_model.dart';

class SongCard extends StatelessWidget {
  final Song song;

  const SongCard({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading:
            song.imageUrl != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: Image.network(
                    song.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.music_note, size: 50);
                    },
                  ),
                )
                : const Icon(Icons.music_note, size: 50),
        title: Text(
          song.title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.more_vert),
        onTap: () {
          // TODO: Implement song playback
        },
      ),
    );
  }
}
