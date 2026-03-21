import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../application/providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _loading = false;
  String? _message;
  String? _error;

  Future<void> _checkVerified() async {
    setState(() {
      _loading = true;
      _message = null;
      _error = null;
    });
    try {
      final verified =
          await ref.read(authProvider.notifier).reloadAndCheckEmailVerified();
      if (!verified && mounted) {
        setState(() {
          _error = 'Email not verified yet. Please check your inbox.';
        });
      }
      // If verified, router redirect handles navigation to /home automatically.
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _message = null;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).sendEmailVerification();
      if (mounted) {
        setState(() {
          _message = 'Verification email sent. Check your inbox.';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).signOut();
    // Router redirect handles navigation to /login.
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authProvider).valueOrNull?.user?.email;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Verify your email',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 64,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(height: 24),
              Text(
                'We sent a verification link to:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              if (email != null) ...[
                const SizedBox(height: 8),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Click the link in the email, then tap the button below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFEF4444)),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6366F1)),
                ),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                label: _loading ? 'Checking...' : "I've verified my email",
                onPressed: _loading ? null : _checkVerified,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loading ? null : _resend,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Resend verification email',
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : _signOut,
                child: Text(
                  'Sign out',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
