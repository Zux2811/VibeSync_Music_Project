// lib/presentation/player/widgets/player_menu.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:music_app/presentation/subscription/upgrade_pro_page.dart';

// Skyblue color scheme
const Color kSkyBlue = Color(0xFF0EA5E9);

class PlayerMenu extends StatelessWidget {
  final VoidCallback onAddToPlaylist;
  final VoidCallback onViewArtist;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onToggleAutoMix;
  final bool canDownload;
  final bool isAutoMixEnabled;
  final int crossfadeDuration;

  const PlayerMenu({
    Key? key,
    required this.onAddToPlaylist,
    required this.onViewArtist,
    required this.onDownload,
    required this.onShare,
    required this.onToggleAutoMix,
    required this.canDownload,
    this.isAutoMixEnabled = false,
    this.crossfadeDuration = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const highlight = kSkyBlue;

    return PopupMenuButton<String>(
      icon: const FaIcon(
        FontAwesomeIcons.ellipsisVertical,
        color: Colors.white70,
      ),
      color: const Color(0xFF1E1E2E),
      elevation: 8,
      onSelected: (value) async {
        switch (value) {
          case 'playlist':
            onAddToPlaylist();
            break;
          case 'artist':
            onViewArtist();
            break;
          case 'automix':
            onToggleAutoMix();
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
        const textColor = Colors.white;
        final subtextColor = Colors.white.withOpacity(0.6);

        final items = <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'automix',
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.shuffle,
                  color: isAutoMixEnabled ? highlight : subtextColor,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AutoMix',
                        style: TextStyle(
                          color: textColor,
                          fontWeight:
                              isAutoMixEnabled
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                      Text(
                        isAutoMixEnabled
                            ? 'Bật • Crossfade ${crossfadeDuration}s'
                            : 'Chuyển bài mượt mà',
                        style: TextStyle(
                          color: isAutoMixEnabled ? highlight : subtextColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAutoMixEnabled)
                  const Icon(Icons.check_circle, color: highlight, size: 18),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'playlist',
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.listUl,
                  color: highlight,
                  size: 18,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add to Playlist',
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'artist',
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.user, color: highlight, size: 18),
                const SizedBox(width: 12),
                const Text('View Artist', style: TextStyle(color: textColor)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'download',
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.download,
                  color: highlight,
                  size: 18,
                ),
                const SizedBox(width: 12),
                const Text('Download', style: TextStyle(color: textColor)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'share',
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.share,
                  color: highlight,
                  size: 18,
                ),
                const SizedBox(width: 12),
                const Text('Share', style: TextStyle(color: textColor)),
              ],
            ),
          ),
        ];
        return items;
      },
    );
  }
}
