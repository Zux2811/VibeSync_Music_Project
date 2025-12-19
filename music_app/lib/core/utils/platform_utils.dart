import 'package:flutter/foundation.dart' show kIsWeb;

/// Check if running on web platform
bool get isWeb => kIsWeb;

/// Check if running on mobile platform
bool get isMobile => !kIsWeb;
