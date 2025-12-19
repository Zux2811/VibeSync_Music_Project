import 'dart:typed_data';

/// Stub implementation for web - no cropping available
Future<Uint8List?> cropImage(String path) async {
  // On web, cropping is not supported, return null to use original image
  return null;
}
