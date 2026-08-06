import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the current session is a guest (anonymous) session.
final isGuestProvider = NotifierProvider<GuestNotifier, bool>(GuestNotifier.new);

class GuestNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
