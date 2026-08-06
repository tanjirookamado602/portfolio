import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:flutter/services.dart';

class RiveBanner extends StatefulWidget {
  final String asset; // local .riv path, e.g. 'assets/animations/hero.riv'
  final double height;
  const RiveBanner({super.key, required this.asset, this.height = 180});

  @override
  State<RiveBanner> createState() => _RiveBannerState();
}

class _RiveBannerState extends State<RiveBanner> {
  Artboard? _artboard;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    try {
      final data = await rootBundle.load(widget.asset);
      final file = RiveFile.import(data);
      setState(() => _artboard = file.mainArtboard
        ..addController(SimpleAnimation('idle')));
    } catch (_) {
      // ignore errors; artboard will stay null and fallback will be used by parent
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_artboard == null) {
      return SizedBox(
          height: widget.height, child: const Center(child: SizedBox()));
    }
    return SizedBox(height: widget.height, child: Rive(artboard: _artboard!));
  }
}
