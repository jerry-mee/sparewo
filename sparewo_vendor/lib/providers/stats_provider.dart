// lib/providers/stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stats_service.dart';
import '../models/dashboard_stats.dart';
import '../constants/enums.dart';
import 'providers.dart';

class StatsState {
  final DashboardStats? stats;
  final LoadingStatus status;
  final String? error;
  final bool isLoading;

  const StatsState({
    this.stats,
    this.status = LoadingStatus.initial,
    this.error,
    this.isLoading = false,
  });

  StatsState copyWith({
    DashboardStats? stats,
    LoadingStatus? status,
    String? error,
    bool? isLoading,
  }) {
    return StatsState(
      stats: stats ?? this.stats,
      status: status ?? this.status,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  AsyncValue<DashboardStats> toAsyncValue() {
    if (isLoading) return const AsyncValue.loading();
    if (error != null) return AsyncValue.error(error!, StackTrace.current);
    if (stats != null) return AsyncValue.data(stats!);
    return const AsyncValue.loading();
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  // FIX: Make the service nullable to support the empty state.
  final StatsService? _statsService;
  final String? _vendorId;

  StatsNotifier(this._statsService, this._vendorId)
      : super(const StatsState()) {
    if (_vendorId != null) {
      loadStats();
    }
  }

  // FIX: Add the .empty() factory constructor.
  // This creates an instance of the notifier that does nothing,
  // which is safe for when a user is logged out.
  factory StatsNotifier.empty() {
    return StatsNotifier(null, null);
  }

  Future<void> loadStats() async {
    // FIX: Add guards to prevent execution if the notifier is empty.
    if (state.isLoading || _vendorId == null || _statsService == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // FIX: Use the null-check operator (!) because we've guarded against null above.
      final stats = await _statsService!.getDashboardStats(_vendorId!);
      state = state.copyWith(
        stats: stats,
        status: LoadingStatus.success,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        status: LoadingStatus.error,
        isLoading: false,
      );
    }
  }

  Stream<DashboardStats> watchStats() {
    // FIX: Return an empty stream if the notifier is in an empty state.
    if (_vendorId == null || _statsService == null) {
      return Stream.value(DashboardStats.empty());
    }
    // FIX: Use the null-check operator (!)
    return _statsService!.watchDashboardStats(_vendorId!);
  }
}

// NOTE: The providers below are correct and do not need changes.
// They correctly use the refactored StatsNotifier.
final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  final statsService = ref.watch(statsServiceProvider);
  final vendorId = ref.watch(currentVendorIdProvider);

  if (vendorId == null) {
    return StatsNotifier.empty();
  }

  return StatsNotifier(statsService, vendorId);
});

final statsAsyncProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  return ref.watch(statsProvider).toAsyncValue();
});

final statsStreamProvider = StreamProvider<DashboardStats>((ref) {
  return ref.watch(statsProvider.notifier).watchStats();
});

final statsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(statsProvider.select((state) => state.isLoading));
});

final statsErrorProvider = Provider<String?>((ref) {
  return ref.watch(statsProvider.select((state) => state.error));
});

final statsStatusProvider = Provider<LoadingStatus>((ref) {
  return ref.watch(statsProvider.select((state) => state.status));
});
