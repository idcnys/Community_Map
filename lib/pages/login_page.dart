
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/push_notification_service.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/validators.dart';
import '../core/utils/snackbar_helper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/guest_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Previous sign-in detection
  String? _lastSignInMethod; // 'email' | 'google'
  String? _lastEmail;
  bool _showFullForm = false;

  @override
  void initState() {
    super.initState();
    _checkPreviousSignIn();
  }

  Future<void> _checkPreviousSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    final method = prefs.getString('last_sign_in_method');
    final email = prefs.getString('last_sign_in_email');
    if (method != null && mounted) {
      setState(() {
        _lastSignInMethod = method;
        _lastEmail = email;
      });
    }
  }

  static Future<void> storeSignInMethod(String method, {String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sign_in_method', method);
    if (email != null) await prefs.setString('last_sign_in_email', email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;
      // Block login until the email is verified.
      if (user != null && !user.emailVerified) {
        if (mounted) context.go('/verify-email');
        return;
      }

      // Register FCM token for push notifications
      PushNotificationService().registerToken();
      storeSignInMethod('email', email: _emailController.text.trim());

      if (mounted) {
        context.go('/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'এই ইমেইল দিয়ে কোনো অ্যাকাউন্ট পাওয়া যায়নি।';
        case 'wrong-password':
          message = 'ভুল পাসওয়ার্ড। আবার চেষ্টা করুন।';
        case 'invalid-email':
          message = 'একটি সঠিক ইমেইল ঠিকানা লিখুন।';
        case 'user-disabled':
          message = 'এই অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে।';
        case 'invalid-credential':
          message = 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।';
        case 'too-many-requests':
          message = 'অনেক বেশি চেষ্টা হয়েছে। পরে আবার চেষ্টা করুন।';
        default:
          message = e.message ?? 'লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';
      }

      if (mounted) {
        context.showError(message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show streamlined "Continue with..." screen if previous sign-in detected
    if (_lastSignInMethod != null && !_showFullForm) {
      return _buildWelcomeBack(theme);
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    LucideIcons.lock,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ফিরে আসায় স্বাগতম',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'আপনার অ্যাকাউন্টে সাইন ইন করুন',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'ইমেইল',
                      hintText: 'আপনি@example.com',
                      prefixIcon: Icon(LucideIcons.mail),
                    ),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'পাসওয়ার্ড',
                      hintText: 'আপনার পাসওয়ার্ড লিখুন',
                      prefixIcon: const Icon(LucideIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _handleForgotPassword(),
                      child: const Text('পাসওয়ার্ড ভুলে গেছেন?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('সাইন ইন', style: TextStyle(fontFamily: 'EkusheInter', fontSize: 16)),
                  ),
                  const SizedBox(height: 12),

                  // Google Sign-In Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Image.asset('assets/icon/google_logo.png', width: 24, height: 24),
                    label: const Text('গুগল দিয়ে সাইন ইন করুন', style: TextStyle(fontFamily: 'EkusheInter', fontSize: 16)),
                  ),
                  const SizedBox(height: 12),

                  // Guest Login Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGuestLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(LucideIcons.eye),
                    label: const Text('অতিথি হিসেবে লগইন করুন', style: TextStyle(fontFamily: 'EkusheInter', fontSize: 16)),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'অ্যাকাউন্ট নেই? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/signup');
                        },
                        child: const Text(
                          'সাইন আপ',
                          style: TextStyle(fontFamily: 'EkusheInter', fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  static bool _googleSignInInitialized = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn.instance;
      if (!_googleSignInInitialized) {
        await googleSignIn.initialize();
        _googleSignInInitialized = true;
      }

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Auto-create profile on first Google sign-in (BEFORE registerToken,
      // because registerToken uses merge:true which creates a partial doc)
      final user = userCredential.user;
      if (user != null) {
        // Update Firebase Auth display name (same as email sign-up)
        final displayName = googleUser.displayName ?? '';
        if (displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
        }

        final profileRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final profileSnap = await profileRef.get();
        if (!profileSnap.exists) {
          await profileRef.set({
            'fullName': displayName,
            'email': googleUser.email,
            'imageUrl': googleUser.photoUrl ?? '',
            'bio': '',
            'phone': '',
            'location': '',
            'dateOfBirth': '',
            'bloodGroup': '',
            'hobby': '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
      }

      // Register FCM token AFTER profile creation
      PushNotificationService().registerToken();
      storeSignInMethod('google', email: googleUser.email);

      if (mounted) context.go('/dashboard');
    } on FirebaseAuthException catch (e) {
      if (mounted) context.showError('গুগল সাইন-ইন ব্যর্থ হয়েছে: ${e.message}');
    } catch (e) {
      if (mounted) context.showError('গুগল সাইন-ইন ব্যর্থ হয়েছে: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        // Reuse existing anonymous session — no new profile created
        await GuestSession.setActive(true);
      } else {
        // First guest login on this device
        await FirebaseAuth.instance.signInAnonymously();
        await GuestSession.setActive(true);
      }

      ref.read(isGuestProvider.notifier).set(true);
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) context.showError('অতিথি লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildWelcomeBack(ThemeData theme) {
    final isGoogle = _lastSignInMethod == 'google';
    final displayEmail = _lastEmail ?? '';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  LucideIcons.lock,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'ফিরে আসায় স্বাগতম',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isGoogle
                      ? 'আপনার গুগল অ্যাকাউন্ট দিয়ে চালিয়ে যান'
                      : 'আপনার ইমেইল দিয়ে চালিয়ে যান',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (displayEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 48),

                // Continue button
                FilledButton.icon(
                  onPressed: _isLoading ? null : (isGoogle ? _handleGoogleSignIn : _continueWithEmail),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isGoogle
                      ? Image.asset('assets/icon/google_logo.png', width: 22, height: 22)
                      : const Icon(LucideIcons.mail, size: 20),
                  label: Text(
                    isGoogle ? 'গুগল দিয়ে চালিয়ে যান' : 'ইমেইল দিয়ে চালিয়ে যান',
                    style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Guest option
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGuestLogin,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(LucideIcons.eye),
                  label: const Text('অতিথি হিসেবে লগইন করুন', style: TextStyle(fontFamily: 'EkusheInter', fontSize: 16)),
                ),
                const SizedBox(height: 32),

                // Use different account
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showFullForm = true),
                    child: const Text('অন্য একটি অ্যাকাউন্ট ব্যবহার করুন'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _continueWithEmail() {
    setState(() {
      _showFullForm = true;
      if (_lastEmail != null) {
        _emailController.text = _lastEmail!;
      }
    });
  }

  Future<void> _handleForgotPassword() async {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('পাসওয়ার্ড রিসেট করুন'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'ইমেইল',
            hintText: 'আপনার নিবন্ধিত ইমেইল লিখুন',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('পাসওয়ার্ড রিসেট ইমেইল পাঠানো হয়েছে!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('রিসেট ইমেইল পাঠানো যায়নি: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('পাঠান'),
          ),
        ],
      ),
    );
  }
}
