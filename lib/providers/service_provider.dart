import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_history.dart';
import '../models/service_component.dart';
import '../models/vehicle_info.dart';
import '../models/user_model.dart';
import '../models/service_notification.dart';
import '../models/workshop_model.dart';
import '../repositories/service_repository.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

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

// =============================================================================
// ADVANCE FEATURE 1: AUTHENTICATION (Supabase Auth & Sesi Pengguna)
// =============================================================================
class AuthNotifier extends AsyncNotifier<UserModel?> {
  static const String authStorageKey = 'servisku_auth_user_v1';
  static const String registeredUsersStorageKey = 'servisku_registered_users_v2';

  @override
  Future<UserModel?> build() async {
    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    
    // Pastikan akun default tersedia untuk mode demo/offline
    await _ensureDefaultRegisteredUsers(prefs);

    // 1. Cek sesi aktif di Supabase Auth
    final sbClient = SupabaseService.client;
    if (sbClient != null) {
      final sbUser = sbClient.auth.currentUser;
      if (sbUser != null) {
        return UserModel(
          id: sbUser.id,
          nama: sbUser.userMetadata?['nama']?.toString() ?? sbUser.email?.split('@').first.toUpperCase() ?? 'Pengguna',
          email: sbUser.email ?? '',
          createdAt: DateTime.tryParse(sbUser.createdAt) ?? DateTime.now(),
          isGuest: false,
        );
      }
    }

    // 2. Cek penyimpanan sesi lokal
    final jsonStr = prefs.getString(authStorageKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return UserModel.fromJson(jsonStr);
      } catch (_) {}
    }

    // Jika belum login, return null agar mewajibkan login terlebih dahulu
    return null;
  }

  Future<void> _ensureDefaultRegisteredUsers(SharedPreferences prefs) async {
    final raw = prefs.getString(registeredUsersStorageKey);
    if (raw == null || raw.isEmpty) {
      final defaultList = [
        {
          'id': 'usr-001',
          'nama': 'Budi Rider',
          'email': 'budi.rider@gmail.com',
          'password': 'password123',
          'createdAt': DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
          'isGuest': false,
        }
      ];
      await prefs.setString(registeredUsersStorageKey, json.encode(defaultList));
    }
  }

  /// Mendapatkan daftar akun yang sudah terdaftar
  Future<List<Map<String, dynamic>>> getRegisteredUsers() async {
    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    await _ensureDefaultRegisteredUsers(prefs);
    final raw = prefs.getString(registeredUsersStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(raw);
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    return [];
  }

  /// Login dengan Email dan Password (Terhubung ke Supabase Auth dengan fallback lokal)
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    final sbClient = SupabaseService.client;
    if (sbClient != null) {
      try {
        final res = await sbClient.auth.signInWithPassword(
          email: trimmedEmail,
          password: trimmedPassword,
        );
        final sbUser = res.user;
        if (sbUser != null) {
          final user = UserModel(
            id: sbUser.id,
            nama: sbUser.userMetadata?['nama']?.toString() ?? trimmedEmail.split('@').first.toUpperCase(),
            email: sbUser.email ?? trimmedEmail,
            createdAt: DateTime.tryParse(sbUser.createdAt) ?? DateTime.now(),
            isGuest: false,
          );
          final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
          await prefs.setString(authStorageKey, user.toJson());
          state = AsyncValue.data(user);
          return;
        }
      } on AuthException catch (e) {
        state = const AsyncValue.data(null);
        throw Exception(e.message);
      } catch (_) {
        // Fallback jika belum terhubung ke jaringan
      }
    }

    // Fallback verifikasi akun lokal
    await Future.delayed(const Duration(milliseconds: 300));
    final users = await getRegisteredUsers();
    final matchedIndex = users.indexWhere(
      (u) => (u['email'] as String? ?? '').toLowerCase() == trimmedEmail,
    );

    if (matchedIndex == -1) {
      state = const AsyncValue.data(null);
      throw Exception('Akun belum terdaftar! Silakan lakukan pendaftaran akun terlebih dahulu.');
    }

    final userMap = users[matchedIndex];
    if (userMap['password'] != trimmedPassword) {
      state = const AsyncValue.data(null);
      throw Exception('Kata sandi salah. Silakan periksa kembali kata sandi Anda.');
    }

    final user = UserModel.fromMap(userMap);
    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    await prefs.setString(authStorageKey, user.toJson());
    state = AsyncValue.data(user);
  }

  /// Login via Gmail / Google
  Future<void> loginWithGoogle(String email) async {
    state = const AsyncValue.loading();
    final trimmedEmail = email.trim().toLowerCase();

    final sbClient = SupabaseService.client;
    if (sbClient != null) {
      try {
        // Coba login jika akun terdaftar di Supabase
        final users = await getRegisteredUsers();
        final matched = users.where((u) => (u['email'] as String? ?? '').toLowerCase() == trimmedEmail);
        if (matched.isNotEmpty && matched.first['password'] != null) {
          final res = await sbClient.auth.signInWithPassword(
            email: trimmedEmail,
            password: matched.first['password'],
          );
          final sbUser = res.user;
          if (sbUser != null) {
            final user = UserModel(
              id: sbUser.id,
              nama: sbUser.userMetadata?['nama']?.toString() ?? trimmedEmail.split('@').first.toUpperCase(),
              email: sbUser.email ?? trimmedEmail,
              createdAt: DateTime.tryParse(sbUser.createdAt) ?? DateTime.now(),
              isGuest: false,
            );
            final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
            await prefs.setString(authStorageKey, user.toJson());
            state = AsyncValue.data(user);
            return;
          }
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 350));
    final users = await getRegisteredUsers();
    final matchedIndex = users.indexWhere(
      (u) => (u['email'] as String? ?? '').toLowerCase() == trimmedEmail,
    );

    if (matchedIndex == -1) {
      state = const AsyncValue.data(null);
      throw Exception(
        'Akun Gmail ($trimmedEmail) belum terdaftar di ServisKu! Hanya akun yang sudah terdaftar yang dapat masuk. Silakan registrasi terlebih dahulu.',
      );
    }

    final userMap = users[matchedIndex];
    final user = UserModel.fromMap(userMap);
    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    await prefs.setString(authStorageKey, user.toJson());
    state = AsyncValue.data(user);
  }

  /// Registrasi Akun Baru (Daftarkan ke Supabase Auth & lokal)
  Future<void> register(String nama, String email, String password) async {
    state = const AsyncValue.loading();
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();
    final trimmedNama = nama.trim();

    final sbClient = SupabaseService.client;
    if (sbClient != null) {
      try {
        final res = await sbClient.auth.signUp(
          email: trimmedEmail,
          password: trimmedPassword,
          data: {'nama': trimmedNama},
        );
        final sbUser = res.user;
        if (sbUser != null) {
          final user = UserModel(
            id: sbUser.id,
            nama: trimmedNama,
            email: sbUser.email ?? trimmedEmail,
            createdAt: DateTime.tryParse(sbUser.createdAt) ?? DateTime.now(),
            isGuest: false,
          );
          final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
          await prefs.setString(authStorageKey, user.toJson());

          final users = await getRegisteredUsers();
          users.removeWhere((u) => (u['email'] as String? ?? '').toLowerCase() == trimmedEmail);
          users.add({
            'id': sbUser.id,
            'nama': trimmedNama,
            'email': trimmedEmail,
            'password': trimmedPassword,
            'createdAt': DateTime.now().toIso8601String(),
            'isGuest': false,
          });
          await prefs.setString(registeredUsersStorageKey, json.encode(users));

          state = AsyncValue.data(user);
          return;
        }
      } on AuthException catch (e) {
        state = const AsyncValue.data(null);
        throw Exception(e.message);
      } catch (_) {
        // Fallback lokal
      }
    }

    await Future.delayed(const Duration(milliseconds: 350));
    final users = await getRegisteredUsers();
    final exists = users.any(
      (u) => (u['email'] as String? ?? '').toLowerCase() == trimmedEmail,
    );

    if (exists) {
      state = const AsyncValue.data(null);
      throw Exception('Email ini sudah terdaftar. Silakan langsung masuk (login).');
    }

    final newUserMap = {
      'id': 'usr-${DateTime.now().millisecondsSinceEpoch}',
      'nama': trimmedNama,
      'email': trimmedEmail,
      'password': trimmedPassword,
      'createdAt': DateTime.now().toIso8601String(),
      'isGuest': false,
    };

    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    users.add(newUserMap);
    await prefs.setString(registeredUsersStorageKey, json.encode(users));

    final user = UserModel.fromMap(newUserMap);
    await prefs.setString(authStorageKey, user.toJson());
    state = AsyncValue.data(user);
  }

  Future<void> loginAsGuest() async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 150));
    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    await prefs.setString(authStorageKey, UserModel.guestUser.toJson());
    state = AsyncValue.data(UserModel.guestUser);
  }

  /// Keluar dari akun (Sign Out dari Supabase & Sesi Lokal)
  Future<void> logout() async {
    try {
      await SupabaseService.client?.auth.signOut();
    } catch (_) {}
    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    await prefs.remove(authStorageKey);
    state = const AsyncValue.data(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

// =============================================================================
// ADVANCE FEATURE 2: NOTIFIKASI PENGINGAT SERVIS (Service Reminder & Permissions)
// =============================================================================
enum NotificationPermissionStatus { notDetermined, granted, denied }

class NotificationPermissionNotifier extends Notifier<NotificationPermissionStatus> {
  @override
  NotificationPermissionStatus build() => NotificationPermissionStatus.granted;

  void setStatus(NotificationPermissionStatus status) => state = status;
}

final notificationPermissionProvider = NotifierProvider<NotificationPermissionNotifier, NotificationPermissionStatus>(() {
  return NotificationPermissionNotifier();
});

class NotificationNotifier extends AsyncNotifier<List<ServiceNotification>> {
  static const String storageKey = 'servisku_notifications_v1';

  @override
  Future<List<ServiceNotification>> build() async {
    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(storageKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
        return decoded.map((e) => ServiceNotification.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    // Default preset notifications
    return [
      ServiceNotification(
        id: 'notif-init-1',
        title: 'Pengingat Ganti Oli Mesin',
        message: 'Odometer motor Anda saat ini 10.000 km. Waktunya cek atau ganti oli mesin.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        type: 'reminder',
        componentName: 'Oli Mesin',
        isUrgent: true,
      ),
      ServiceNotification(
        id: 'notif-init-2',
        title: 'Servis Berkala Siap',
        message: 'Busi dan Filter Udara dalam kondisi baik. Estimasi servis berikutnya pada 14.000 km.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        type: 'success',
        componentName: 'Busi',
        isUrgent: false,
      ),
    ];
  }

  Future<void> addNotification(ServiceNotification notification) async {
    if (state.hasValue) {
      final current = state.value!;
      final updated = [notification, ...current];
      state = AsyncValue.data(updated);
      _persist(updated);
    }
  }

  Future<void> markAsRead(String id) async {
    if (state.hasValue) {
      final updated = state.value!.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
      state = AsyncValue.data(updated);
      _persist(updated);
    }
  }

  Future<void> markAllAsRead() async {
    if (state.hasValue) {
      final updated = state.value!.map((n) => n.copyWith(isRead: true)).toList();
      state = AsyncValue.data(updated);
      _persist(updated);
    }
  }

  Future<void> clearAll() async {
    state = const AsyncValue.data([]);
    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<void> _persist(List<ServiceNotification> list) async {
    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toMap()).toList();
    await prefs.setString(storageKey, json.encode(jsonList));
  }
}

final notificationProvider = AsyncNotifierProvider<NotificationNotifier, List<ServiceNotification>>(() {
  return NotificationNotifier();
});

// =============================================================================
// ADVANCE FEATURE 3: LOKASI & BENGKEL GOOGLE MAPS (GPS & Permission Handling)
// =============================================================================
enum LocationPermissionState {
  unknown,
  requesting,
  granted,
  denied,
  cancelled,
}

class LocationState {
  final LocationPermissionState permission;
  final double latitude;
  final double longitude;
  final String locationName;
  final String? errorMessage;

  const LocationState({
    required this.permission,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.errorMessage,
  });

  // Default coordinate: Gading Serpong, Tangerang
  static const defaultLocation = LocationState(
    permission: LocationPermissionState.granted,
    latitude: -6.2550,
    longitude: 106.6200,
    locationName: 'Gading Serpong, Tangerang Selatan',
  );
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => LocationState.defaultLocation;

  void requestPermission() {
    state = LocationState(
      permission: LocationPermissionState.requesting,
      latitude: state.latitude,
      longitude: state.longitude,
      locationName: state.locationName,
    );
  }

  void grantPermission({double? lat, double? lng, String? locName}) {
    state = LocationState(
      permission: LocationPermissionState.granted,
      latitude: lat ?? -6.2550,
      longitude: lng ?? 106.6200,
      locationName: locName ?? 'Gading Serpong, Tangerang Selatan (GPS Aktif)',
    );
  }

  void denyPermission() {
    state = const LocationState(
      permission: LocationPermissionState.denied,
      latitude: -6.2000,
      longitude: 106.8166,
      locationName: 'Lokasi Default (Izin Ditolak)',
      errorMessage: 'Akses izin lokasi ditolak oleh pengguna. Menggunakan lokasi default.',
    );
  }

  void cancelPermission() {
    state = const LocationState(
      permission: LocationPermissionState.cancelled,
      latitude: -6.2000,
      longitude: 106.8166,
      locationName: 'Lokasi Default (Permintaan Dibatalkan)',
      errorMessage: 'Permintaan akses lokasi dibatalkan.',
    );
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(() {
  return LocationNotifier();
});

// Filter kategori bengkel
class WorkshopFilterCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'Semua';

  void setCategory(String category) => state = category;
}

final workshopFilterCategoryProvider = NotifierProvider<WorkshopFilterCategoryNotifier, String>(() {
  return WorkshopFilterCategoryNotifier();
});

class WorkshopSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final workshopSearchQueryProvider = NotifierProvider<WorkshopSearchQueryNotifier, String>(() {
  return WorkshopSearchQueryNotifier();
});

// List bengkel terdekat yang diurutkan
final nearbyWorkshopsProvider = Provider<List<Workshop>>((ref) {
  final location = ref.watch(locationProvider);
  final category = ref.watch(workshopFilterCategoryProvider);
  final search = ref.watch(workshopSearchQueryProvider).toLowerCase();

  var list = List<Workshop>.from(Workshop.defaultWorkshops);

  if (category != 'Semua') {
    list = list.where((w) => w.kategori == category || (category == 'Resmi' && w.isOfficial)).toList();
  }

  if (search.isNotEmpty) {
    list = list.where((w) =>
        w.nama.toLowerCase().contains(search) ||
        w.alamat.toLowerCase().contains(search) ||
        w.kategori.toLowerCase().contains(search)).toList();
  }

  // Hitung ulang jarak dinamis terhadap koordinat pengguna saat ini
  list.sort((a, b) => a.hitungJarak(location.latitude, location.longitude)
      .compareTo(b.hitungJarak(location.latitude, location.longitude)));

  return list;
});
