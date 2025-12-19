import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// http import not needed - using ApiService
import '../../data/sources/api_service.dart';

// Conditional import for mobile-only features
import 'avatar_cropper_stub.dart'
    if (dart.library.io) 'avatar_cropper_mobile.dart'
    as cropper;

class AvatarSelectionPage extends StatefulWidget {
  final bool isGoogleSignIn;

  const AvatarSelectionPage({super.key, this.isGoogleSignIn = false});

  @override
  State<AvatarSelectionPage> createState() => _AvatarSelectionPageState();
}

class _AvatarSelectionPageState extends State<AvatarSelectionPage> {
  Uint8List? _imageBytes; // Image bytes (works on both web and mobile)
  String? _imageUrl; // URL for network image (Google avatar)
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isGoogleSignIn) {
      _loadGoogleAvatar();
    }
  }

  Future<void> _loadGoogleAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final googleAvatarUrl = prefs.getString('google_avatar_url');
    if (googleAvatarUrl != null && googleAvatarUrl.isNotEmpty) {
      setState(() {
        _imageUrl = googleAvatarUrl;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        if (kIsWeb) {
          // On web, just use the bytes directly
          setState(() {
            _imageBytes = bytes;
            _imageUrl = null;
          });
        } else {
          // On mobile, try to crop the image
          final croppedBytes = await cropper.cropImage(pickedFile.path);
          setState(() {
            _imageBytes = croppedBytes ?? bytes;
            _imageUrl = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi chọn ảnh: $e')));
      }
    }
  }

  Future<void> _onConfirm() async {
    if (_imageBytes == null && _imageUrl == null) return;

    setState(() => _isUploading = true);

    try {
      String? avatarUrl;

      if (_imageBytes != null) {
        // Upload custom image to server
        avatarUrl = await ApiService.uploadAvatar(_imageBytes!);
      } else if (_imageUrl != null) {
        // Use Google avatar URL directly
        avatarUrl = _imageUrl;
      }

      if (avatarUrl != null) {
        // Update profile with avatar URL
        await ApiService.updateProfile(avatarUrl: avatarUrl);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar_url', avatarUrl);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/onboarding_theme_selection');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _onUseGoogleDefault() async {
    if (_imageUrl != null) {
      setState(() => _isUploading = true);
      try {
        await ApiService.updateProfile(avatarUrl: _imageUrl!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar_url', _imageUrl!);
      } catch (e) {
        // Best effort - continue anyway
      }
      if (mounted) setState(() => _isUploading = false);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding_theme_selection');
  }

  void _skipAvatar() {
    Navigator.of(context).pushReplacementNamed('/onboarding_theme_selection');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn ảnh đại diện'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _skipAvatar,
            child: Text('Bỏ qua', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular Avatar Picker
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _hasImage
                                  ? colorScheme.primary
                                  : Colors.grey.shade300,
                          width: _hasImage ? 3 : 2,
                        ),
                        color:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                      ),
                      child: ClipOval(child: _buildAvatarImage()),
                    ),
                    // Camera icon overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Helper text
              Text(
                kIsWeb
                    ? 'Nhấn vào ảnh để chọn từ thiết bị'
                    : 'Nhấn vào ảnh để chọn và cắt ảnh',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              if (widget.isGoogleSignIn && _imageUrl != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Hoặc sử dụng ảnh từ Google',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(),

              // Action buttons
              if (_isUploading)
                const CircularProgressIndicator()
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _hasImage ? _onConfirm : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    if (widget.isGoogleSignIn && _imageUrl != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _onUseGoogleDefault,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sử dụng ảnh Google',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasImage => _imageBytes != null || _imageUrl != null;

  Widget _buildAvatarImage() {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      );
    } else if (_imageUrl != null) {
      return Image.network(
        _imageUrl!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 200,
      height: 200,
      color: Colors.grey.shade200,
      child: Icon(Icons.person, size: 80, color: Colors.grey.shade400),
    );
  }
}
