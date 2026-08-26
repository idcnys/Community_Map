
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/validators.dart';
import '../core/utils/snackbar_helper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // Create auth user
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;
      if (user == null) {
        if (mounted) context.showError('অ্যাকাউন্ট তৈরি ব্যর্থ হয়েছে। আবার চেষ্টা করুন।');
        return;
      }

      // Update display name
      await user.updateDisplayName(_fullNameController.text.trim());

      // Register FCM token for push notifications
      PushNotificationService().registerToken();

      // Remember sign-in method for next launch
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sign_in_method', 'email');
      await prefs.setString('last_sign_in_email', _emailController.text.trim());

      // Store profile in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'dateOfBirth': _selectedDate?.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Send verification email (non-fatal if it fails; can resend later).
      try {
        await user.sendEmailVerification();
      } catch (_) {
        // Ignore; user can resend from the verify screen.
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('অ্যাকাউন্ট তৈরি হয়েছে! আপনার ইমেইল যাচাই করুন।'),
            backgroundColor: Colors.green,
          ),
        );
        // Keep the user signed in so they can resend; the router guard
        // blocks dashboard access until the email is verified.
        context.go('/verify-email');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'এই ইমেইলটি ইতিমধ্যে নিবন্ধিত।';
        case 'invalid-email':
          message = 'একটি সঠিক ইমেইল ঠিকানা লিখুন।';
        case 'weak-password':
          message = 'পাসওয়ার্ডটি খুব দুর্বল। কমপক্ষে ৬ অক্ষর ব্যবহার করুন।';
        case 'operation-not-allowed':
          message = 'ইমেইল/পাসওয়ার্ড অ্যাকাউন্ট সক্রিয় করা হয়নি।';
        default:
          message = e.message ?? 'সাইন আপ ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('কিছু একটা সমস্যা হয়েছে: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('অ্যাকাউন্ট তৈরি করুন'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  LucideIcons.userPlus,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'সাইন আপ',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'শুরু করতে আপনার অ্যাকাউন্ট তৈরি করুন',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'পুরো নাম',
                    hintText: 'জন ডো',
                    prefixIcon: Icon(LucideIcons.user),
                  ),
                  validator: validateName,
                ),
                const SizedBox(height: 16),

                // Date of Birth
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: const InputDecoration(
                    labelText: 'জন্ম তারিখ',
                    hintText: 'DD/MM/YYYY',
                    prefixIcon: Icon(LucideIcons.calendar),
                    suffixIcon: Icon(LucideIcons.chevronDown),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'আপনার জন্ম তারিখ নির্বাচন করুন';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'পাসওয়ার্ড',
                    hintText: 'কমপক্ষে ৬ অক্ষর',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'একটি পাসওয়ার্ড লিখুন';
                    }
                    if (value.length < 6) {
                      return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'পাসওয়ার্ড নিশ্চিত করুন',
                    hintText: 'আপনার পাসওয়ার্ড আবার লিখুন',
                    prefixIcon: const Icon(LucideIcons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? LucideIcons.eye
                            : LucideIcons.eyeOff,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'আপনার পাসওয়ার্ড নিশ্চিত করুন';
                    }
                    if (value != _passwordController.text) {
                      return 'পাসওয়ার্ড মিলছে না';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Sign Up Button
                FilledButton(
                  onPressed: _isLoading ? null : _handleSignUp,
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
                      : const Text('অ্যাকাউন্ট তৈরি করুন',
                          style: TextStyle(fontFamily: 'EkusheInter', fontSize: 16)),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ইতিমধ্যে একটি অ্যাকাউন্ট আছে? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'সাইন ইন',
                        style: TextStyle(fontFamily: 'EkusheInter', fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
