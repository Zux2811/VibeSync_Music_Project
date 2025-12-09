// lib/presentation/player/widgets/player_menu.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:music_app/presentation/subscription/upgrade_pro_page.dart';

class PlayerMenu extends StatelessWidget {
  final VoidCallback onAddToPlaylist;
  final VoidCallback onViewArtist;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final bool canDownload;

  const PlayerMenu({
    Key? key,
    required this.onAddToPlaylist,
    required this.onViewArtist,
    required this.onDownload,
    required this.onShare,
    required this.canDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor =
        theme.appBarTheme.foregroundColor ?? theme.iconTheme.color;
    final highlight = theme.colorScheme.primary;

    return PopupMenuButton<String>(
      icon: FaIcon(FontAwesomeIcons.ellipsisVertical, color: iconColor),
      color: theme.colorScheme.surface,
      elevation: 8,
      onSelected: (value) async {
        switch (value) {
          case 'playlist':
            onAddToPlaylist();
            break;
          case 'artist':
            onViewArtist();
            break;
          case 'download':
            if (canDownload) {
              onDownload();
            } else {
              // Gate download behind Pro subscription
              await showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Yêu cầu gói Pro'),
                      content: const Text(
                        'bạn cần nâng cấp gói pro để tải được bài hát',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Để sau'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            // Navigate to Upgrade Pro page
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const UpgradeProPage(),
                              ),
                            );
                          },
                          child: const Text('Nâng cấp Pro'),
                        ),
                      ],
                    ),
              );
            }
            break;
          case 'share':
            onShare();
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        final items = <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'playlist',
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.listUl, color: highlight, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Add to Playlist',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'artist',
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.user, color: highlight, size: 18),
                const SizedBox(width: 12),
                Text(
                  'View Artist',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'download',
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.download, color: highlight, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Download',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'share',
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.share, color: highlight, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Share',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ];
        return items;
      },
    );
  }
}
