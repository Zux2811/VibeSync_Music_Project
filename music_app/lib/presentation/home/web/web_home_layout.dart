import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../player/player_provider.dart';
import 'web_main_content.dart';
import 'web_player_bar.dart';
import '../tabs/search_tab.dart';
import '../tabs/library/library_tab.dart';

class WebHomeLayout extends StatefulWidget {
  const WebHomeLayout({super.key});

  @override
  State<WebHomeLayout> createState() => _WebHomeLayoutState();
}

class _WebHomeLayoutState extends State<WebHomeLayout> {
  String _selectedMenu = 'Home';

  Widget _getPageForMenu(String menu) {
    switch (menu) {
      case 'Home':
        return const WebMainContent();
      case 'Search':
      case 'Albums':
      case 'Artists':
        return const SearchTab(); // Reuse search tab for now
      case 'Favourites':
      case 'Popular':
      case 'My Playlist':
        return const LibraryTab();
      default:
        return const WebMainContent();
    }
  }

  final List<_MenuSection> _menuSections = [
    _MenuSection(
      title: 'Menu',
      items: [
        _MenuItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
        ),
        _MenuItem(
          icon: Icons.search_outlined,
          activeIcon: Icons.search,
          label: 'Search',
        ),
        _MenuItem(
          icon: Icons.album_outlined,
          activeIcon: Icons.album,
          label: 'Albums',
        ),
        _MenuItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Artists',
        ),
      ],
    ),
    _MenuSection(
      title: 'Library',
      items: [
        _MenuItem(
          icon: Icons.favorite_outline,
          activeIcon: Icons.favorite,
          label: 'Favourites',
        ),
        _MenuItem(
          icon: Icons.trending_up_outlined,
          activeIcon: Icons.trending_up,
          label: 'Popular',
        ),
        _MenuItem(
          icon: Icons.playlist_play_outlined,
          activeIcon: Icons.playlist_play,
          label: 'My Playlist',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          // Main content with sidebar
          Expanded(
            child: Row(
              children: [
                // Left Sidebar Navigation
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBgLight : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo & App Name
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'VibeSync',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark ? Colors.white : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Menu title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textDarkSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Menu Sections
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children:
                              _menuSections.expand((section) {
                                return [
                                  // Section items
                                  ...section.items.map(
                                    (item) => _buildMenuItem(
                                      context,
                                      item: item,
                                      isSelected: _selectedMenu == item.label,
                                      onTap: () {
                                        setState(
                                          () => _selectedMenu = item.label,
                                        );
                                      },
                                      isDark: isDark,
                                      primaryColor: primaryColor,
                                    ),
                                  ),
                                  // Divider after Menu section
                                  if (section.title == 'Menu')
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                      child: Text(
                                        'LIBRARY',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDark
                                                  ? AppColors.textSecondary
                                                  : AppColors.textDarkSecondary,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                ];
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedMenu),
                      child: _getPageForMenu(_selectedMenu),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Player Bar
          Consumer<PlayerProvider>(
            builder: (context, provider, _) {
              if (provider.currentSong == null) {
                return const SizedBox.shrink();
              }
              return const WebPlayerBar();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required _MenuItem item,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor:
              isDark ? AppColors.darkBgLighter : AppColors.lightElevated,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? (isDark
                          ? AppColors.darkBgLighter
                          : AppColors.lightElevated)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 22,
                  color:
                      isSelected
                          ? primaryColor
                          : (isDark
                              ? AppColors.textSecondary
                              : AppColors.textDarkSecondary),
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected
                            ? (isDark ? Colors.white : AppColors.textDark)
                            : (isDark
                                ? AppColors.textSecondary
                                : AppColors.textDarkSecondary),
                  ),
                ),
                if (isSelected) const Spacer(),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuSection {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});
}

class _MenuItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _MenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
