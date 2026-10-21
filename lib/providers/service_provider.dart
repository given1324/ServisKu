import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_history.dart';
import '../models/service_component.dart';
import '../models/vehicle_info.dart';
import '../repositories/service_repository.dart';

import '../services/api_service.dart';

// Provider untuk instance SharedPreferences opsional (dapat di-override di main/test)
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  return null;
});

// Provider untuk instance ApiService (dapat di-override di test dengan mock http client)
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provider untuk ServiceRepository yang menghubungkan Notifier ke Backend API & local cache
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final api = ref.watch(apiServiceProvider);
  return ServiceRepository(prefs: prefs, apiService: api);
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

  // Fungsi untuk merefresh/memuat ulang data dari local persistence
  Future<void> refreshData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }

  // Fungsi untuk menambah data servis (Create)
  Future<void> addService(ServiceHistory service) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.addServiceHistory(service);
    
    // Update local state secara reaktif tanpa menduplikasi data
    if (state.hasValue) {
      final currentList = state.value!.where((e) => e.id != service.id).toList();
      state = AsyncValue.data([service, ...currentList]);
    } else {
      ref.invalidateSelf();
    }
  }

  // Fungsi untuk memperbarui data servis (Update)
  Future<void> updateService(ServiceHistory service) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.updateServiceHistory(service);
    
    if (state.hasValue) {
      final updatedList = state.value!.map((e) => e.id == service.id ? service : e).toList();
      state = AsyncValue.data(updatedList);
    } else {
      ref.invalidateSelf();
    }
  }

  // Fungsi untuk menghapus data servis (Delete)
  Future<void> deleteService(String id) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.deleteServiceHistory(id);
    
    if (state.hasValue) {
      final updatedList = state.value!.where((e) => e.id != id).toList();
      state = AsyncValue.data(updatedList);
    } else {
      ref.invalidateSelf();
    }
  }
}

// Provider untuk ServiceHistoryNotifier
final serviceHistoryProvider = AsyncNotifierProvider<ServiceHistoryNotifier, List<ServiceHistory>>(() {
  return ServiceHistoryNotifier();
});

// AsyncNotifier untuk profil kendaraan (motor)
class VehicleInfoNotifier extends AsyncNotifier<VehicleInfo> {
  @override
  Future<VehicleInfo> build() async {
    final repository = ref.read(serviceRepositoryProvider);
    return await repository.fetchVehicleInfo();
  }

  // Fungsi untuk memperbarui data motor
  Future<void> updateVehicleInfo(VehicleInfo newInfo) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.saveVehicleInfo(newInfo);
    state = AsyncValue.data(newInfo);
  }
}

// Provider untuk VehicleInfoNotifier
final vehicleInfoProvider = AsyncNotifierProvider<VehicleInfoNotifier, VehicleInfo>(() {
  return VehicleInfoNotifier();
});

// AsyncNotifier untuk daftar komponen servis berkala
class ServiceComponentsNotifier extends AsyncNotifier<List<ServiceComponent>> {
  @override
  Future<List<ServiceComponent>> build() async {
    final repository = ref.read(serviceRepositoryProvider);
    return await repository.fetchComponents();
  }

  // Tambah komponen servis baru
  Future<void> addComponent(ServiceComponent component) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.addComponent(component);
    if (state.hasValue) {
      final current = state.value!.where((e) => e.id != component.id).toList();
      state = AsyncValue.data([...current, component]);
    } else {
      ref.invalidateSelf();
    }
  }

  // Update komponen servis
  Future<void> updateComponent(ServiceComponent component) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.updateComponent(component);
    if (state.hasValue) {
      final updated = state.value!.map((e) => e.id == component.id ? component : e).toList();
      state = AsyncValue.data(updated);
    } else {
      ref.invalidateSelf();
    }
  }

  // Hapus komponen servis
  Future<void> deleteComponent(String id) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.deleteComponent(id);
    if (state.hasValue) {
      final updated = state.value!.where((e) => e.id != id).toList();
      state = AsyncValue.data(updated);
    } else {
      ref.invalidateSelf();
    }
  }
}

// Provider untuk ServiceComponentsNotifier
final serviceComponentsProvider = AsyncNotifierProvider<ServiceComponentsNotifier, List<ServiceComponent>>(() {
  return ServiceComponentsNotifier();
});
