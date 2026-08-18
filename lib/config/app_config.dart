class AppConfig {
  /// The base URL for the web version of the community app.
  static const String webBaseUrl = 'https://com-app-project.web.app';

  /// The domain host for deep linking.
  static const String deepLinkHost = 'com-app-project.web.app';

  /// The scheme for deep linking (usually https).
  static const String deepLinkScheme = 'https';
  
  /// Helper to generate a member profile URL
  static String getMemberUrl(String memberId, {String? familyDocId}) {
    String url = '$webBaseUrl/member?id=$memberId';
    if (familyDocId != null) {
      url += '&family=$familyDocId';
    }
    return url;
  }
}
