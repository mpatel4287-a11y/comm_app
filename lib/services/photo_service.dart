// lib/services/photo_service.dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'imagekit_service.dart';
import 'imagekit_config.dart';

class PhotoService {
  final ImageKitService _imageKitService = ImageKitService();

  PhotoService();

  /// Check if ImageKit is properly configured
  bool get isImageKitConfigured => ImageKitService.isConfigured;

  /// Upload profile photo using ImageKit
  Future<String?> uploadProfilePhoto({
    required String memberId,
    required XFile image,
  }) async {
    try {
      // Read the image file
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      final fileName =
          'profile_${memberId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to ImageKit
      final photoUrl = await _imageKitService.uploadFile(
        fileBytes: bytes,
        fileName: fileName,
        folder: ImageKitConfig.profilePhotoFolder,
        customMetadata: {
          'memberId': memberId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      return photoUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  /// Delete profile photo from ImageKit
  Future<void> deleteProfilePhoto(String photoUrl) async {
    if (!isImageKitConfigured) {
      print('ImageKit not configured. Cannot delete photo.');
      return;
    }

    try {
      // Note: File deletion requires server-side implementation
      print('File deletion should be handled server-side for security');
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }

  /// Get optimized/thumbnail URL for profile photo
  String getOptimizedUrl(String photoUrl, {int width = 200, int height = 200}) {
    return _imageKitService.getOptimizedUrl(
      photoUrl,
      width: width,
      height: height,
    );
  }

  /// Get thumbnail URL for list views
  String getThumbnailUrl(String photoUrl, {int size = 100}) {
    return _imageKitService.getThumbnailUrl(photoUrl, size: size);
  }

  /// Get medium size URL for detail views
  String getMediumUrl(String photoUrl, {int width = 400, int height = 400}) {
    return _imageKitService.getOptimizedUrl(
      photoUrl,
      width: width,
      height: height,
    );
  }

  /// Pick image from gallery
  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: ImageKitConfig.maxImageWidth.toDouble(),
      maxHeight: ImageKitConfig.maxImageHeight.toDouble(),
      imageQuality: ImageKitConfig.imageQuality,
    );
  }

  /// Pick image from camera
  Future<XFile?> pickFromCamera() async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: ImageKitConfig.maxImageWidth.toDouble(),
      maxHeight: ImageKitConfig.maxImageHeight.toDouble(),
      imageQuality: ImageKitConfig.imageQuality,
    );
  }
}
