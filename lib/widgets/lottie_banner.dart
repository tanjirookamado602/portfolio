import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieBanner extends StatelessWidget {
  final double height;
  final String url;
  const LottieBanner(
      {super.key,
      this.height = 160,
      this.url =
          'https://assets7.lottiefiles.com/packages/lf20_jcikwtux.json'});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Lottie.network(url, fit: BoxFit.contain, repeat: true),
      ),
    );
  }
}
