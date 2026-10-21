import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'comprehensive_admin_panel.dart';

/// AdminGate: shows a secure, modern sign-in form (email/password) and only
/// displays the admin panel after successful Firebase authentication.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text;
      if (email.isEmpty || pass.isEmpty) {
        setState(() {
          _error = 'Please enter both email and password.';
          _loading = false;
        });
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Sign-in failed (${e.code})';
      });
    } catch (e) {
      setState(() {
        _error = 'Sign-in failed: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildSignInCard() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderSubtle,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Icon Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentPrimary.withOpacity(0.2),
                          AppTheme.accentSecondary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accentPrimary.withOpacity(0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 36,
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title & Subtitle
                Center(
                  child: Text(
                    'Portfolio CMS',
                    style: AppTheme.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Sign in to manage portfolio content & inquiries',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyTextStyle.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Email input
                Text(
                  'Admin Email',
                  style: AppTheme.labelMeta.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTheme.bodyTextStyle.copyWith(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'admin@example.com',
                    hintStyle: TextStyle(color: AppTheme.textFaint),
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted, size: 20),
                    filled: true,
                    fillColor: AppTheme.bgSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.accentPrimary, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _signIn(),
                ),
                const SizedBox(height: 18),

                // Password input
                Text(
                  'Password',
                  style: AppTheme.labelMeta.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  style: AppTheme.bodyTextStyle.copyWith(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(color: AppTheme.textFaint),
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppTheme.bgSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.accentPrimary, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _signIn(),
                ),
                const SizedBox(height: 16),

                // Error alert
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Sign In Button
                ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Sign In to Dashboard',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Return to portfolio link
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                    icon: Icon(Icons.arrow_back_rounded, size: 16, color: AppTheme.textMuted),
                    label: Text(
                      'Back to Portfolio Website',
                      style: AppTheme.labelMeta.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        // Only grant access if signed in with credentials (not anonymous)
        if (user != null && !user.isAnonymous) {
          return const ComprehensiveAdminPanel();
        }

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          appBar: AppBar(
            backgroundColor: AppTheme.bgPrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
              tooltip: 'Back to website',
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
            ),
            title: Text(
              'Portfolio Admin Sign In',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
            ),
          ),
          body: _buildSignInCard(),
        );
      },
    );
  }
}
