import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the current session is a guest (anonymous) session.
final isGuestProvider = NotifierProvider<GuestNotifier, bool>(GuestNotifier.new);

class GuestNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Manages the persistent guest session flag.
/// The anonymous Firebase user is NEVER signed out — we just toggle
/// this flag so the router/UI treat the device as "logged out".
/// This ensures only ONE anonymous identity exists per device.
class GuestSession {
  static const _key = 'guest_session_active';
  static bool isActive = false;

  /// Call once at app startup (splash page) to hydrate the flag.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isActive = prefs.getBool(_key) ?? false;
  }

  static Future<void> setActive(bool value) async {
    isActive = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
