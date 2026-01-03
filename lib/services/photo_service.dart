// lib/services/photo_service.dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class PhotoService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile photo
  Future<String?> uploadProfilePhoto({
    required String memberId,
    required XFile image,
  }) async {
    try {
      final fileName = path.basename(image.path);
      final ref = _storage.ref().child('profile_photos/$memberId/$fileName');

      await ref.putFile(File(image.path));
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  // Delete profile photo
  Future<void> deleteProfilePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
  }

  // Pick image from camera
  Future<XFile?> pickFromCamera() async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
  }
}
