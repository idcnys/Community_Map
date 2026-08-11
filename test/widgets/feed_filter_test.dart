import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cmap/providers/feed_providers.dart';

void main() {
  group('FeedFilterNotifier widget integration', () {
    testWidgets('default filter is "all"', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(builder: (context, ref, _) {
              final filter = ref.watch(feedFilterProvider);
              return Text(filter, textDirection: TextDirection.ltr);
            }),
          ),
        ),
      );

      expect(find.text('all'), findsOneWidget);
    });

    testWidgets('setFilter updates UI', (tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(builder: (context, ref, _) {
              capturedRef = ref;
              final filter = ref.watch(feedFilterProvider);
              return Text(filter, textDirection: TextDirection.ltr);
            }),
          ),
        ),
      );

      expect(find.text('all'), findsOneWidget);

      // Change filter to 'public'
      capturedRef.read(feedFilterProvider.notifier).setFilter('public');
      await tester.pump();

      expect(find.text('public'), findsOneWidget);
    });

    testWidgets('setFilter to group ID updates UI', (tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(builder: (context, ref, _) {
              capturedRef = ref;
              final filter = ref.watch(feedFilterProvider);
              return Text(filter, textDirection: TextDirection.ltr);
            }),
          ),
        ),
      );

      capturedRef.read(feedFilterProvider.notifier).setFilter('group123');
      await tester.pump();

      expect(find.text('group123'), findsOneWidget);
    });
  });
}
