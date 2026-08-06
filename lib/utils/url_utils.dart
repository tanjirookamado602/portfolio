import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  static String? sanitizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    String trimmed = url.trim();

    if (trimmed.contains('github.com')) {
      if (trimmed.contains('/blob/')) {
        trimmed = trimmed.replaceFirst('/blob/', '/');
      } else if (trimmed.contains('/raw/')) {
        trimmed = trimmed.replaceFirst('/raw/', '/');
      }
      trimmed = trimmed.replaceFirst('github.com', 'raw.githubusercontent.com');
    }

    if (trimmed.contains('drive.google.com')) {
      final idMatch = RegExp(r"/d/([a-zA-Z0-9_-]+)").firstMatch(trimmed) ??
          RegExp(r"[?&]id=([a-zA-Z0-9_-]+)").firstMatch(trimmed);

      if (idMatch != null && idMatch.groupCount >= 1) {
        final id = idMatch.group(1);
        return 'https://drive.google.com/uc?export=view&id=$id';
      }
    }

    return trimmed;
  }

  static String? convertDriveLink(String? url) => sanitizeUrl(url);

  static Future<void> launch(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      String formattedLink = url.trim();
      if (!formattedLink.startsWith('http://') && !formattedLink.startsWith('https://') && !formattedLink.startsWith('mailto:') && !formattedLink.startsWith('tel:')) {
        formattedLink = 'https://$formattedLink';
      }
      final uri = Uri.parse(formattedLink);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }
}
