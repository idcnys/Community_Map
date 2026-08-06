import 'package:go_router/go_router.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/feed/comments_page.dart';
import 'pages/feed/community_post_form.dart';
import 'pages/manage/profile_editor_page.dart';
import 'pages/manage/group_detail_page.dart';

/// Centralized router configuration.
final router = GoRouter(
  initialLocation: '/login',
  routes: [
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
            return CommentsPage(
              postId: postId,
              postAuthorId: postAuthorId,
            );
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
