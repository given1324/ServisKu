import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_history.dart';
import '../repositories/service_repository.dart';

// Provider untuk ServiceRepository
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository();
});

// AsyncNotifier untuk mengelola state data riwayat servis
class ServiceHistoryNotifier extends AsyncNotifier<List<ServiceHistory>> {
  @override
  Future<List<ServiceHistory>> build() async {
    return _fetchData();
  }

  Future<List<ServiceHistory>> _fetchData() async {
    final repository = ref.read(serviceRepositoryProvider);
    return await repository.fetchServiceHistory();
  }

  // Fungsi untuk merefresh/memuat ulang data
  Future<void> refreshData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }

  // Fungsi untuk menambah data servis
  Future<void> addService(ServiceHistory service) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.addServiceHistory(service);
    
    // Update local state setelah berhasil ditambahkan ke "API"
    if (state.hasValue) {
      state = AsyncValue.data([service, ...state.value!]);
    } else {
      ref.invalidateSelf(); // Opsi fallback: Muat ulang data dari awal
    }
  }
}

// Provider untuk ServiceHistoryNotifier
final serviceHistoryProvider = AsyncNotifierProvider<ServiceHistoryNotifier, List<ServiceHistory>>(() {
  return ServiceHistoryNotifier();
});
