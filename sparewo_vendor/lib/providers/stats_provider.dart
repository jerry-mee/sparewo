// lib/providers/stats_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stats_service.dart';
import '../models/dashboard_stats.dart';
import '../constants/enums.dart';
import 'service_providers.dart';

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
  final StatsService _statsService;
  final String? _vendorId;

  StatsNotifier(this._statsService, this._vendorId)
      : super(const StatsState()) {
    if (_vendorId != null) {
      loadStats();
    }
  }

  Future<void> loadStats() async {
    if (state.isLoading || _vendorId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final stats = await _statsService.getDashboardStats(_vendorId!);
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
    if (_vendorId == null) {
      return Stream.value(DashboardStats.empty());
    }
    return _statsService.watchDashboardStats(_vendorId!);
  }
}

// -------------------------------------------
// Updated Provider Definition Section
// -------------------------------------------

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  final statsService = ref.watch(statsServiceProvider);
  final vendorId = ref.watch(currentUserIdProvider);
  return StatsNotifier(statsService, vendorId);
});

// -------------------------------------------
// Derived Providers Section
// -------------------------------------------

// These providers remain unchanged.

final statsAsyncProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  return ref.watch(statsProvider).toAsyncValue();
});

final statsStreamProvider = StreamProvider<DashboardStats>((ref) {
  return ref.watch(statsProvider.notifier).watchStats();
});

final statsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(statsProvider).isLoading;
});

final statsErrorProvider = Provider<String?>((ref) {
  return ref.watch(statsProvider).error;
});

final statsStatusProvider = Provider<LoadingStatus>((ref) {
  return ref.watch(statsProvider).status;
});
