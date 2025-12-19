import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Mobile implementation for image cropping
Future<Uint8List?> cropImage(String path) async {
  try {
    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt ảnh đại diện',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Cắt ảnh đại diện',
          doneButtonTitle: 'Xong',
          cancelButtonTitle: 'Hủy',
          aspectRatioLockEnabled: true,
          cropStyle: CropStyle.circle,
        ),
      ],
    );

    if (croppedFile != null) {
      return await File(croppedFile.path).readAsBytes();
    }
  } catch (e) {
    debugPrint('Error cropping image: $e');
  }
  return null;
}
