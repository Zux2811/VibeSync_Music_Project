import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AvatarChoice { none, custom, googleDefault }

class AvatarSelectionPage extends StatefulWidget {
  final bool isGoogleSignIn;

  const AvatarSelectionPage({super.key, this.isGoogleSignIn = false});

  @override
  State<AvatarSelectionPage> createState() => _AvatarSelectionPageState();
}

class _AvatarSelectionPageState extends State<AvatarSelectionPage> {
  String? _selectedAvatar; // path of chosen avatar to persist on Next
  File? _croppedImageFile; // custom-picked image file
  File? _googleDefaultFile; // downloaded Google avatar file

  AvatarChoice _choice = AvatarChoice.none;

  @override
  void initState() {
    super.initState();
    _restorePreviousAvatarIfAny();
  }

  Future<void> _restorePreviousAvatarIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    if (onboardingComplete) return; // Do not interfere outside onboarding

    final savedPath = prefs.getString('user_avatar');
    if (savedPath == null || savedPath.isEmpty) return;

    final file = File(savedPath);
    final exists = await file.exists();
    if (!mounted) return;
    if (exists) {
      setState(() {
        _selectedAvatar = savedPath;
        if (widget.isGoogleSignIn) {
          // Treat saved path as Google default avatar
          _googleDefaultFile = file;
          _choice = AvatarChoice.googleDefault;
        } else {
          _croppedImageFile = file;
          _choice = AvatarChoice.custom;
        }
      });
    }
  }

  Future<void> _pickAndCropImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Bạn có thể di chuyển hoặc zoom ảnh',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Bạn có thể di chuyển hoặc zoom ảnh',
            doneButtonTitle: 'Xong',
            cancelButtonTitle: 'Hủy',
            aspectRatioLockEnabled: true,
            cropStyle: CropStyle.circle,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _croppedImageFile = File(croppedFile.path);
          _selectedAvatar = croppedFile.path;
        });
      }
    }
  }

  void _onConfirm() async {
    if (_selectedAvatar == null) return;
    final prefs = await SharedPreferences.getInstance();

    // Persist the picked/cropped file path
    await prefs.setString('user_avatar', _selectedAvatar!);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding_theme_selection');
  }

  void _onUseGoogleDefault() async {
    // Use Google's default avatar without modification
    final prefs = await SharedPreferences.getInstance();
    // Keep the existing user_avatar (Google's avatar) and proceed
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding_theme_selection');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn ảnh đại diện'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular Avatar Picker
              GestureDetector(
                onTap: _pickAndCropImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular container with border
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _croppedImageFile != null
                                  ? colorScheme.primary
                                  : Colors.grey.shade300,
                          width: _croppedImageFile != null ? 3 : 2,
                        ),
                        color: Colors.grey.shade100,
                      ),
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            _croppedImageFile != null
                                ? FileImage(_croppedImageFile!)
                                : null,
                      ),
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
                              color: Colors.black.withAlpha(51),
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
              const SizedBox(height: 48),

              // Text label for Google default avatar
              if (widget.isGoogleSignIn)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Sử dụng ảnh đại diện mặc định của google',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

              const Spacer(),

              // Action buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _selectedAvatar != null ? _onConfirm : null,
                    child: const Text('Xác nhận'),
                  ),
                  const SizedBox(height: 12),
                  if (widget.isGoogleSignIn)
                    OutlinedButton(
                      onPressed: _onUseGoogleDefault,
                      child: const Text('Sử dụng mặc định'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
