import 'package:flutter/material.dart';
import '../utils/url_utils.dart';

class PlatformImageImpl extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const PlatformImageImpl({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Sanitize URL for IO as well, to handle GitHub raw links correctly
    final sanitizedUrl = UrlUtils.sanitizeUrl(imageUrl) ?? imageUrl;

    Widget image = Image.network(
      sanitizedUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.withOpacity(0.1),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}
