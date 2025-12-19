import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Responsive breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1800;
}

/// Device type enum
enum DeviceType { mobile, tablet, desktop, largeDesktop }

/// Responsive utility class
class Responsive {
  final BuildContext context;

  Responsive(this.context);

  /// Get screen width
  double get width => MediaQuery.of(context).size.width;

  /// Get screen height
  double get height => MediaQuery.of(context).size.height;

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile platform
  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check if running on desktop platform
  static bool get isDesktopPlatform {
    if (kIsWeb) return true; // Treat web as desktop for layout purposes
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Get current device type based on screen width
  DeviceType get deviceType {
    if (width < Breakpoints.mobile) return DeviceType.mobile;
    if (width < Breakpoints.tablet) return DeviceType.tablet;
    if (width < Breakpoints.desktop) return DeviceType.desktop;
    return DeviceType.largeDesktop;
  }

  /// Check if current device is mobile (based on screen width)
  bool get isMobile => width < Breakpoints.mobile;

  /// Check if current device is tablet
  bool get isTablet =>
      width >= Breakpoints.mobile && width < Breakpoints.tablet;

  /// Check if current device is desktop
  bool get isDesktop => width >= Breakpoints.tablet;

  /// Check if current device is large desktop
  bool get isLargeDesktop => width >= Breakpoints.desktop;

  /// Get number of columns for grid based on screen size
  int get gridColumns {
    if (isMobile) return 2;
    if (isTablet) return 3;
    if (isDesktop) return 4;
    return 5;
  }

  /// Get horizontal padding based on screen size
  double get horizontalPadding {
    if (isMobile) return 16;
    if (isTablet) return 24;
    if (isDesktop) return 32;
    return 48;
  }

  /// Get content max width for centered layouts
  double get maxContentWidth {
    if (isMobile) return double.infinity;
    if (isTablet) return 720;
    if (isDesktop) return 1140;
    return 1400;
  }

  /// Get sidebar width for desktop
  double get sidebarWidth {
    if (isLargeDesktop) return 280;
    if (isDesktop) return 240;
    return 200;
  }

  /// Get player height based on device
  double get miniPlayerHeight {
    if (isMobile) return 64;
    return 72;
  }

  /// Get bottom nav bar height
  double get bottomNavHeight {
    if (isMobile) return 60;
    return 70;
  }

  /// Get appropriate font scale
  double get fontScale {
    if (isMobile) return 1.0;
    if (isTablet) return 1.05;
    return 1.1;
  }

  /// Get card aspect ratio
  double get cardAspectRatio {
    if (isMobile) return 0.85;
    if (isTablet) return 0.9;
    return 1.0;
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive responsive) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, Responsive(context));
      },
    );
  }
}

/// Widget that shows different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    if (responsive.isDesktop && desktop != null) {
      return desktop!;
    }

    if (responsive.isTablet && tablet != null) {
      return tablet!;
    }

    return mobile;
  }
}

/// Centered content wrapper with max width
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? responsive.maxContentWidth,
        ),
        padding:
            padding ??
            EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
        child: child,
      ),
    );
  }
}

/// Responsive grid view
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? forcedColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.forcedColumns,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final columns = forcedColumns ?? responsive.gridColumns;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: runSpacing,
        crossAxisSpacing: spacing,
        childAspectRatio: responsive.cardAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Web-aware scaffold that adds hover effects and desktop styling
class WebAwareScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const WebAwareScaffold({
    super.key,
    this.appBar,
    this.body,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    // For desktop, use a different layout with persistent sidebar
    if (responsive.isDesktop && drawer != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        body: Row(
          children: [
            // Persistent sidebar
            SizedBox(width: responsive.sidebarWidth, child: drawer),
            // Main content
            Expanded(child: body ?? const SizedBox()),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // For mobile/tablet, use standard scaffold
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
