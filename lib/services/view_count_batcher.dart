import 'dart:async';
import 'post_service.dart';

/// Batches view count increments and flushes periodically.
/// Instead of one Firestore write per view, accumulates IDs and
/// writes them in a single batch every [flushInterval].
class ViewCountBatcher {
  final _pendingIds = <String>{};
  Timer? _flushTimer;
  final Duration flushInterval;
  final PostService _service;

  ViewCountBatcher({
    this.flushInterval = const Duration(seconds: 10),
    PostService? service,
  }) : _service = service ?? PostService();

  /// Queue a post ID for view count increment.
  void trackView(String postId) {
    _pendingIds.add(postId);
    _scheduleFlush();
  }

  void _scheduleFlush() {
    _flushTimer ??= Timer(flushInterval, flush);
  }

  /// Write all pending view counts as a single Firestore batch.
  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_pendingIds.isEmpty) return;

    final ids = _pendingIds.toList();
    _pendingIds.clear();

    try {
      await _service.incrementViews(ids);
    } catch (_) {
      // Re-queue on failure
      _pendingIds.addAll(ids);
      _scheduleFlush();
    }
  }

  /// Call on app dispose to flush remaining views.
  void dispose() {
    flush();
    _flushTimer?.cancel();
  }
}
