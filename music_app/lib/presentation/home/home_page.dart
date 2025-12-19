import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_app/presentation/home/tabs/settings_tab.dart';
import '../../core/constants/app_colors.dart';
import 'tabs/home_tab.dart';
import 'tabs/search_tab.dart';
import 'tabs/library/library_tab.dart';
import '../player/player_provider.dart';
import '../player/widgets/mini_player.dart';
import 'web/web_home_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animController;

  final List<Widget> _pages = const [
    HomeTab(),
    SearchTab(),
    LibraryTab(),
    SettingsTab(),
  ];

  final List<NavItem> _navItems = const [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: "Home",
    ),
    NavItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: "Search",
    ),
    NavItem(
      icon: Icons.library_music_outlined,
      activeIcon: Icons.library_music_rounded,
      label: "Library",
    ),
    NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: "Settings",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _animController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use web layout for web platform with larger screens
    if (kIsWeb && MediaQuery.of(context).size.width > 900) {
      return const WebHomeLayout();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Main content
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),

          // Mini Player - shows when a song is playing
          Consumer<PlayerProvider>(
            builder: (context, provider, _) {
              if (provider.currentSong == null) {
                return const SizedBox.shrink();
              }
              return const MiniPlayer();
            },
          ),
        ],
      ),
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg : Colors.white,
          border: Border(
            top: BorderSide(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return _buildNavItem(
                  context,
                  item: item,
                  isSelected: isSelected,
                  onTap: () => _onItemTapped(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required NavItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary;
    final selectedColor = primaryColor;
    final unselectedColor =
        isDark ? AppColors.textSecondary : AppColors.textDarkSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? primaryColor.withOpacity(isDark ? 0.15 : 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey(isSelected),
                color: isSelected ? selectedColor : unselectedColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? selectedColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
