import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Test Screen',
              style: AppTheme.heroTextStyle.copyWith(
                fontSize: 48,
                color: AppTheme.accentBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'This is a test to see if content renders',
              style: AppTheme.bodyTextStyle.copyWith(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration(),
              child: Text(
                'If you can see this, the app is working!',
                style: AppTheme.bodyTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
