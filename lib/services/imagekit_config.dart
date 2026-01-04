// lib/services/imagekit_config.dart

/// ImageKit Configuration
///
/// To get your ImageKit credentials:
/// 1. Go to https://imagekit.io and create an account
/// 2. Navigate to Developer Options in your dashboard
/// 3. Copy your Public Key, Private Key, and URL Endpoint
class ImageKitConfig {
  // Replace these with your actual ImageKit credentials
  static const String publicKey = 'public_C0oJSDHjDCn+Mm6ZsOuQMURh5so=';
  static const String privateKey = 'private_VULQsScUEe7UQ5//sNYIIGGSnis=';
  static const String urlEndpoint = ' https://ik.imagekit.io/mcn43wef4p';

  // Configuration for profile photos
  static const String profilePhotoFolder = 'profile_photos';
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  static const int imageQuality = 80;

  /// Initialize ImageKit with credentials
  static String Function(String) get transformationPosition {
    // Returns the URL transformation for ImageKit
    // Example: 'tr:w-1024,h-1024,q-80'
    return (String path) {
      return '$path?tr=w-$maxImageWidth,h-$maxImageHeight,q-$imageQuality';
    };
  }

  /// Validate that configuration is set
  static bool isConfigured() {
    return publicKey != 'your_public_key_here' &&
        privateKey != 'your_private_key_here' &&
        urlEndpoint != 'https://ik.imagekit.io/your_imagekit_id';
  }
}
