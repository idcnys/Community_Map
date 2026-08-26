import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shown after signup (or when an unverified user tries to log in).
/// The user stays signed in here so we can resend the verification email.
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isSending = false;
  bool _isChecking = false;
  bool _canResend = true;
  int _countdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await user.sendEmailVerification();
      _startResendCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('যাচাই ইমেইল পাঠানো হয়েছে! আপনার ইনবক্স দেখুন।'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ইমেইল পাঠানো যায়নি। পরে আবার চেষ্টা করুন।'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startResendCooldown() {
    _countdown = 30;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _countdown = 0;
            _canResend = true;
          });
        }
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _checkVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    setState(() => _isChecking = true);

    try {
      // Pull the latest profile (incl. emailVerified) from the server.
      await user.reload();
      final fresh = FirebaseAuth.instance.currentUser;
      if (fresh != null && fresh.emailVerified) {
        if (mounted) context.go('/dashboard');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ইমেইল এখনো যাচাই হয়নি। আপনার ইনবক্স দেখুন।'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('যাচাইয়ের অবস্থা পরীক্ষা করা যায়নি: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _signOutAndGoLogin() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = FirebaseAuth.instance.currentUser?.email ?? 'আপনার ইমেইল';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ইমেইল যাচাই করুন'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  LucideIcons.mailCheck,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'আপনার ইমেইল যাচাই করুন',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'আমরা একটি যাচাই লিংক পাঠিয়েছি:\n$email\n\n'
                  'অনুগ্রহ করে আপনার ইনবক্স (এবং স্প্যাম ফোল্ডার) দেখুন এবং '
                  'অ্যাকাউন্ট সক্রিয় করতে লিংকে ক্লিক করুন।',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // I have verified
                FilledButton.icon(
                  onPressed: _isChecking ? null : _checkVerified,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.checkCircle),
                  label: Text(
                    _isChecking ? 'পরীক্ষা করা হচ্ছে...' : 'আমি আমার ইমেইল যাচাই করেছি',
                    style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),

                // Resend
                OutlinedButton.icon(
                  onPressed:
                      (_canResend && !_isSending) ? _sendVerification : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.refreshCw),
                  label: Text(
                    _canResend
                        ? 'যাচাই ইমেইল আবার পাঠান'
                        : '${_countdown} সেকেন্ড পরে আবার পাঠান',
                    style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),

                TextButton(
                  onPressed: _signOutAndGoLogin,
                  child: const Text('লগইনে ফিরে যান'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
