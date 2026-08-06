import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'comprehensive_admin_panel.dart';

/// AdminGate: shows a secure sign-in form (email/password) and only
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

      // If sign-in succeeded the stream/listener in build will show the panel.
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Sign-in failed: ${e.code}';
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          color: AppTheme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Admin Sign In', style: AppTheme.cardTitleStyle),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () async {
                              // Optional: allow signing out of any existing session
                              await FirebaseAuth.instance.signOut();
                              _emailCtrl.clear();
                              _passCtrl.clear();
                              setState(() => _error = null);
                            },
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _signIn,
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Sign In'),
                    ),
                  ],
                )
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
        if (user != null) {
          // Signed in — show the admin panel
          return const ComprehensiveAdminPanel();
        }

        // Not signed in — show sign-in form
        return Scaffold(
          backgroundColor: AppTheme.primaryBackground,
          appBar: AppBar(
            title: const Text('Admin Sign In'),
            backgroundColor: AppTheme.primaryBackground,
          ),
          body: _buildSignInCard(),
        );
      },
    );
  }
}
