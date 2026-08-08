import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nearby_place_model.dart';
import '../services/nearby_service.dart';

/// Singleton provider for NearbyService.
final nearbyServiceProvider = Provider<NearbyService>((ref) {
  return NearbyService();
});

/// State for nearby places feature.
class NearbyState {
  final List<NearbyPlace> places;
  final bool isLoading;
  final String? error;
  final Set<NearbyCategory> activeCategories;

  const NearbyState({
    this.places = const [],
    this.isLoading = false,
    this.error,
    this.activeCategories = const {},
  });

  NearbyState copyWith({
    List<NearbyPlace>? places,
    bool? isLoading,
    String? error,
    Set<NearbyCategory>? activeCategories,
    bool clearError = false,
  }) {
    return NearbyState(
      places: places ?? this.places,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeCategories: activeCategories ?? this.activeCategories,
    );
  }
}

/// Notifier managing nearby places state.
class NearbyNotifier extends Notifier<NearbyState> {
  @override
  NearbyState build() => const NearbyState();

  /// Toggle a category on/off and re-fetch.
  void toggleCategory(NearbyCategory category, double lat, double lng) {
    final current = Set<NearbyCategory>.from(state.activeCategories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }

    if (current.isEmpty) {
      state = state.copyWith(places: [], activeCategories: {}, clearError: true);
      return;
    }

    state = state.copyWith(activeCategories: current, clearError: true);
    _fetch(lat, lng, current);
  }

  /// Fetch places for the given categories.
  Future<void> _fetch(
    double lat,
    double lng,
    Set<NearbyCategory> categories,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final service = ref.read(nearbyServiceProvider);
    final result = await service.fetchNearbyPlaces(
      latitude: lat,
      longitude: lng,
      categories: categories.toList(),
    );

    state = state.copyWith(
      places: result.places,
      isLoading: false,
      error: result.error,
      clearError: result.error == null,
    );
  }

  /// Refresh with same categories (e.g. after user moves).
  void refresh(double lat, double lng) {
    if (state.activeCategories.isEmpty) return;
    _fetch(lat, lng, state.activeCategories);
  }

  /// Clear all.
  void clear() {
    state = const NearbyState();
  }
}

final nearbyProvider =
    NotifierProvider<NearbyNotifier, NearbyState>(NearbyNotifier.new);
