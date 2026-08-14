import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';

/// Handles FCM token registration and push delivery via Supabase Edge Function.
class PushNotificationService {
  static String get _supabaseUrl => AppConfig.supabaseUrl;
  static String get _supabaseKey => AppConfig.supabasePublishableKey;
  static String get _functionUrl => '$_supabaseUrl/functions/v1/send-push';

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _messaging = FirebaseMessaging.instance;

  /// Request permission and register FCM token for the current user.
  /// Call once after login/signup.
  Future<void> registerToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) return;

      // Request permission (Android 13+ shows dialog; iOS always)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[Push] Permission denied by user');
        return;
      }

      // Get FCM token
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('[Push] Failed to get FCM token');
        return;
      }

      // Store in Firestore user doc
      await _firestore.collection('users').doc(user.uid).set(
        {'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      debugPrint('[Push] Token registered for ${user.uid}');

      // Listen for token refresh (rare, but needed for long-lived sessions)
      _messaging.onTokenRefresh.listen((newToken) async {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('[Push] registerToken error: $e');
    }
  }

  /// Remove token on logout (prevents push to logged-out device).
  Future<void> unregisterToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmUpdatedAt': FieldValue.delete(),
      });
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[Push] unregisterToken error: $e');
    }
  }

  /// Fetch a user's FCM token from Firestore.
  Future<String?> getFcmToken(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['fcmToken'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Send a push notification via Supabase Edge Function.
  Future<void> sendPush({
    required String targetToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_supabaseKey',
            },
            body: jsonEncode({
              'token': targetToken,
              'title': title,
              'body': body,
              if (data != null) 'data': data,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[Push] sendPush failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[Push] sendPush error: $e');
    }
  }

  /// Send push to a specific user by UID (fetches their token automatically).
  Future<void> pushToUser({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final token = await getFcmToken(targetUserId);
    if (token == null || token.isEmpty) return;
    await sendPush(targetToken: token, title: title, body: body, data: data);
  }

  /// Send push to multiple users (for group notifications).
  Future<void> pushToUsers({
    required List<String> targetUserIds,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (targetUserIds.isEmpty) return;

    // Batch-fetch all tokens in one query
    final snap = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: targetUserIds.take(30).toList())
        .get();

    final tokens = <String>[];
    for (final doc in snap.docs) {
      final token = doc.data()['fcmToken'] as String?;
      if (token != null && token.isNotEmpty) tokens.add(token);
    }

    // Send to all (fire-and-forget, parallel)
    await Future.wait(
      tokens.map((t) => sendPush(targetToken: t, title: title, body: body, data: data)),
      eagerError: false,
    );
  }

}
