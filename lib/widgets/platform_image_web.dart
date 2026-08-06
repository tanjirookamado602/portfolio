// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
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
    final sanitizedUrl = UrlUtils.sanitizeUrl(imageUrl) ?? imageUrl;
    final String viewType = 'img-element-${sanitizedUrl.hashCode}';

    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final img = html.ImageElement();
      img.src = sanitizedUrl;
      img.style.width = '100%';
      img.style.height = '100%';
      img.style.objectFit = _boxFitToCss(fit);

      if (borderRadius != null) {
        img.style.borderRadius = '${borderRadius!.topLeft.x}px';
      }

      return img;
    });

    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView(viewType: viewType),
    );
  }

  String _boxFitToCss(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
      default:
        return 'cover';
    }
  }
}
