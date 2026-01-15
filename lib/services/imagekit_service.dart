// lib/services/imagekit_service.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'imagekit_config.dart';

class ImageKitService {
  static final ImageKitService _instance = ImageKitService._internal();
  factory ImageKitService() => _instance;
  ImageKitService._internal();

  /// Upload file to ImageKit
  Future<String?> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    String folder = 'profile_photos',
    Map<String, String>? customMetadata,
  }) async {
    if (!ImageKitConfig.isConfigured()) {
      print('ImageKit not configured. Check imagekit_config.dart');
      return null;
    }

    try {
      const String uploadUrl =
          'https://upload.imagekit.io/api/v1/files/upload';

      final request =
          http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // File
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      // Required fields
      request.fields['fileName'] = fileName;
      request.fields['folder'] = folder;

      // Optional metadata
      if (customMetadata != null) {
        request.fields['customMetadata'] = jsonEncode(customMetadata);
      }

      // -------- ImageKit AUTH (CORRECT WAY) --------
      final String token = _generateRandomString(30);

      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final String expire = (now + 600).toString(); // +10 minutes

      final String signature = _generateSignature(token, expire);

      request.fields['publicKey'] = ImageKitConfig.publicKey.trim();
      request.fields['token'] = token;
      request.fields['expire'] = expire;
      request.fields['signature'] = signature;

      // Send
      final response = await request.send();
      final responseBody =
          await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['url'] as String?;
      }

      print(
          'ImageKit upload failed: ${response.statusCode} - $responseBody');
      return null;
    } catch (e) {
      print('ImageKit upload exception: $e');
      return null;
    }
  }

  /// Generate HMAC-SHA256 signature
  String _generateSignature(String token, String expire) {
  final key = utf8.encode(ImageKitConfig.privateKey.trim());
  final data = utf8.encode(token + expire);

  final hmacSha1 = Hmac(sha1, key);
  final digest = hmacSha1.convert(data);

  return digest.toString();
}

  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rand.nextInt(chars.length)),
      ),
    );
  }

  /// Generate optimized ImageKit URL
  String getOptimizedUrl(
    String url, {
    int width = 200,
    int height = 200,
    int quality = 80,
    String cropMode = 'at_max',
  }) {
    if (url.isEmpty) return url;

    final cleanUrl = url.trim();
    final transformation =
        'w-$width,h-$height,c-$cropMode,q-$quality';

    if (cleanUrl.contains('?')) {
      return '$cleanUrl&tr=$transformation';
    }
    return '$cleanUrl?tr=$transformation';
  }

  String getThumbnailUrl(String url, {int size = 100}) {
    return getOptimizedUrl(url, width: size, height: size);
  }

  static bool get isConfigured => ImageKitConfig.isConfigured();
}
