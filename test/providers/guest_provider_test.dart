import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/providers/guest_provider.dart';

void main() {
  group('GuestNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is false', () {
      expect(container.read(isGuestProvider), isFalse);
    });

    test('set to true', () {
      container.read(isGuestProvider.notifier).set(true);
      expect(container.read(isGuestProvider), isTrue);
    });

    test('set back to false', () {
      container.read(isGuestProvider.notifier).set(true);
      container.read(isGuestProvider.notifier).set(false);
      expect(container.read(isGuestProvider), isFalse);
    });
  });
}
