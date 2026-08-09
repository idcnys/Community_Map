import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/verify_email_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/feed/comments_page.dart';
import 'pages/feed/community_post_form.dart';
import 'pages/manage/profile_editor_page.dart';
import 'pages/manage/group_detail_page.dart';
import 'pages/splash_page.dart';
import 'providers/guest_provider.dart';
import 'pages/onboarding_page.dart';

/// Converts the Firebase auth-state stream into a [Listenable] so GoRouter
/// re-evaluates its redirect whenever the user signs in/out or reloads.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen(
      (dataFromStream) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Centralized router configuration with an email-verification guard.
final router = GoRouter(
  initialLocation: '/splash',
  refreshListenable: _GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isAnonymous = user?.isAnonymous ?? false;
    final isVerified = user?.emailVerified ?? false;

    final loc = state.matchedLocation;
    final isSplash = loc == '/splash';
    final isAuthScreen = loc == '/login' || loc == '/signup';
    final isVerifyScreen = loc == '/verify-email';

    final isOnboarding = loc == '/onboarding';

    // Allow splash and onboarding to show without redirect
    if (isSplash || isOnboarding) return null;

    // Not signed in -> force to login (unless already there / signing up).
    if (!isLoggedIn) {
      return isAuthScreen ? null : '/login';
    }

    // Anonymous user with inactive guest session -> treat as logged out.
    if (isAnonymous && !GuestSession.isActive) {
      return isAuthScreen ? null : '/login';
    }

    // Signed in but email not verified (and not a guest) -> verify screen.
    if (!isAnonymous && !isVerified) {
      return isVerifyScreen ? null : '/verify-email';
    }

    // Verified user or guest lingering on auth/verify screens -> dashboard.
    if (isAuthScreen || isVerifyScreen) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      path: '/verify-email',
      name: 'verifyEmail',
      builder: (context, state) => const VerifyEmailPage(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardPage(),
      routes: [
        GoRoute(
          path: 'comments/:postId',
          name: 'comments',
          builder: (context, state) {
            final postId = state.pathParameters['postId']!;
            final postAuthorId = state.uri.queryParameters['authorId'] ?? '';
            return CommentsPage(postId: postId, postAuthorId: postAuthorId);
          },
        ),
        GoRoute(
          path: 'create-post',
          name: 'createPost',
          builder: (context, state) => const CommunityPostForm(),
        ),
        GoRoute(
          path: 'profile',
          name: 'profile',
          builder: (context, state) => const ProfileEditorPage(),
        ),
        GoRoute(
          path: 'group/:groupId',
          name: 'groupDetail',
          builder: (context, state) {
            final groupId = state.pathParameters['groupId']!;
            return GroupDetailPage(groupId: groupId);
          },
        ),
      ],
    ),
  ],
);
