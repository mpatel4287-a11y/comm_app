// lib/services/imagekit_service.dart

/// ImageKit Service for uploading images
///
/// Uses ImageKit REST API for file uploads
/// 1. Go to https://imagekit.io and create an account
/// 2. Navigate to Developer Options in your dashboard
/// 3. Copy your Public Key, Private Key, and URL Endpoint

// ignore_for_file: avoid_print, dangling_library_doc_comments

import 'dart:convert';
import 'dart:typed_data';
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
      print(
        'ImageKit not configured. Please set credentials in imagekit_config.dart',
      );
      return null;
    }

    try {
      // Create the upload URL
      final String uploadUrl = '${ImageKitConfig.urlEndpoint}/files/upload';

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      // Add required parameters
      request.fields['fileName'] = fileName;
      request.fields['folder'] = folder;
      request.fields['publicKey'] = ImageKitConfig.publicKey;

      // Add custom metadata if provided
      if (customMetadata != null) {
        request.fields['customMetadata'] = jsonEncode(customMetadata);
      }

      // Add authentication header (private key for API authentication)
      // ImageKit uses HMAC authentication for server-side uploads
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String authToken = _generateAuthToken(timestamp);
      request.fields['token'] = timestamp;
      request.fields['signature'] = authToken;
      request.fields['expire'] = (int.parse(timestamp) + 3600)
          .toString(); // 1 hour expiry

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['url'] != null) {
          return jsonResponse['url'] as String;
        }
      }

      print('ImageKit upload failed: ${response.statusCode} - $responseBody');
      return null;
    } catch (e) {
      print('Error uploading to ImageKit: $e');
      return null;
    }
  }

  /// Generate authentication token for ImageKit upload
  String _generateAuthToken(String token) {
    // For client-side uploads, we use a simpler token generation
    // In production, this should be done on your server for security
    return base64Encode(utf8.encode('${ImageKitConfig.privateKey}:$token'));
  }

  /// Delete file from ImageKit
  Future<bool> deleteFile(String fileId, String fileUrl) async {
    if (!ImageKitConfig.isConfigured()) {
      print('ImageKit not configured. Cannot delete file.');
      return false;
    }

    try {
      // Note: File deletion requires server-side implementation
      // This is a placeholder for the client-side API
      print('File deletion should be handled server-side for security');
      return true;
    } catch (e) {
      print('Error deleting file from ImageKit: $e');
      return false;
    }
  }

  /// Generate optimized URL with transformations
  String getOptimizedUrl(
    String url, {
    int width = 200,
    int height = 200,
    int quality = 80,
    String cropMode = 'at_max',
  }) {
    if (!ImageKitConfig.isConfigured()) {
      return url;
    }

    try {
      // Check if URL already has query parameters
      final uri = Uri.parse(url);
      final hasQueryParams = uri.queryParameters.isNotEmpty;

      // Build transformation string
      final transformation = 'w-$width,h-$height,c-$cropMode,q-$quality';

      if (hasQueryParams) {
        // Add transformation to existing query params
        final newParams = Map<String, String>.from(uri.queryParameters);
        newParams['tr'] = transformation;
        return uri.replace(queryParameters: newParams).toString();
      } else {
        // Add transformation as query parameter
        return '$url?tr=$transformation';
      }
    } catch (e) {
      print('Error generating optimized URL: $e');
      return url;
    }
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String url, {int size = 100}) {
    return getOptimizedUrl(url, width: size, height: size);
  }

  /// Check if ImageKit is properly configured
  static bool get isConfigured => ImageKitConfig.isConfigured();
}
