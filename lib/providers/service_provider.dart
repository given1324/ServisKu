import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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
import '../services/gps_helper.dart';
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
    List<ServiceHistory> updatedHistory;
    if (state.hasValue) {
      final currentList = state.value!.where((e) => e.id != service.id).toList();
      updatedHistory = [service, ...currentList];
      state = AsyncValue.data(updatedHistory);
    } else {
      ref.invalidateSelf();
      updatedHistory = [service];
    }

    // Evaluasi dan kirim notifikasi pengingat servis secara otomatis
    final components = ref.read(serviceComponentsProvider).value ?? ServiceComponent.defaultPresets;
    await ref.read(notificationProvider.notifier).evaluateServiceReminders(
          updatedHistory,
          components,
          newlyAddedService: service,
        );
  }

  // Fungsi untuk memperbarui data servis (Update)
  Future<void> updateService(ServiceHistory service) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.updateServiceHistory(service);
    
    List<ServiceHistory> updatedHistory;
    if (state.hasValue) {
      updatedHistory = state.value!.map((e) => e.id == service.id ? service : e).toList();
      state = AsyncValue.data(updatedHistory);
    } else {
      ref.invalidateSelf();
      updatedHistory = [service];
    }

    final components = ref.read(serviceComponentsProvider).value ?? ServiceComponent.defaultPresets;
    await ref.read(notificationProvider.notifier).evaluateServiceReminders(
          updatedHistory,
          components,
        );
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
        final user = UserModel.fromJson(jsonStr);
        // Abaikan dan bersihkan jika merupakan sisa sesi akun dummy
        if (user.email == 'budi.rider@gmail.com' || user.id == 'usr-001') {
          await prefs.remove(authStorageKey);
          return null;
        }
        return user;
      } catch (_) {}
    }

    // Jika belum login, return null agar mewajibkan login terlebih dahulu
    return null;
  }

  Future<void> _ensureDefaultRegisteredUsers(SharedPreferences prefs) async {
    final raw = prefs.getString(registeredUsersStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(raw);
        // Hapus akun dummy budi.rider jika masih ada di cache lokal
        final filtered = decoded.where((e) {
          final email = (e as Map)['email']?.toString().toLowerCase() ?? '';
          return email != 'budi.rider@gmail.com' && e['id'] != 'usr-001';
        }).toList();
        await prefs.setString(registeredUsersStorageKey, json.encode(filtered));
        return;
      } catch (_) {}
    }
    await prefs.setString(registeredUsersStorageKey, json.encode([]));
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

  /// Menyinkronkan akun Supabase yang berhasil login ke daftar akun lokal browser
  Future<void> _syncLocalRegisteredUser(
    SharedPreferences prefs,
    UserModel user,
    String password,
  ) async {
    final users = await getRegisteredUsers();
    final idx = users.indexWhere(
      (u) => (u['email'] as String? ?? '').toLowerCase() == user.email.toLowerCase(),
    );
    final userMap = {
      'id': user.id,
      'nama': user.nama,
      'email': user.email.toLowerCase(),
      'password': password,
      'createdAt': user.createdAt.toIso8601String(),
      'isGuest': false,
    };
    if (idx == -1) {
      users.add(userMap);
    } else {
      users[idx] = userMap;
    }
    await prefs.setString(registeredUsersStorageKey, json.encode(users));
  }

  /// Login dengan Email dan Password (Terhubung ke Supabase Auth dengan fallback lokal)
  Future<void> login(String email, String password) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    // 1. Coba login melalui Supabase Auth
    final sbClient = SupabaseService.client;
    String? supabaseErrorMsg;
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
          await _syncLocalRegisteredUser(prefs, user, trimmedPassword);
          state = AsyncValue.data(user);
          return;
        }
      } on AuthException catch (e) {
        debugPrint('⚠️ [Supabase Auth] AuthException: ${e.message} (code: ${e.code})');
        final msgLower = e.message.toLowerCase();
        // Supabase hanya mengembalikan 'Email not confirmed' jika email & password VALID
        // namun fitur Confirm Email di dashboard Supabase masih aktif dan belum diklik.
        if (msgLower.contains('email not confirmed') || e.code == 'email_not_confirmed') {
          final user = UserModel(
            id: 'sb-${trimmedEmail.hashCode.abs()}',
            nama: trimmedEmail.split('@').first.toUpperCase(),
            email: trimmedEmail,
            createdAt: DateTime.now(),
            isGuest: false,
          );
          final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
          await prefs.setString(authStorageKey, user.toJson());
          await _syncLocalRegisteredUser(prefs, user, trimmedPassword);
          state = AsyncValue.data(user);
          return;
        }
        supabaseErrorMsg = e.message;
      } catch (e) {
        debugPrint('⚠️ [Supabase Auth] Login via Supabase: $e. Memeriksa database akun lokal...');
      }
    }

    // 2. Fallback verifikasi akun lokal
    await Future.delayed(const Duration(milliseconds: 200));
    final users = await getRegisteredUsers();
    final matchedIndex = users.indexWhere(
      (u) => (u['email'] as String? ?? '').toLowerCase() == trimmedEmail,
    );

    if (matchedIndex == -1) {
      if (supabaseErrorMsg != null && supabaseErrorMsg.toLowerCase().contains('invalid login credentials')) {
        throw Exception(
          'Email atau kata sandi salah, atau akun ($trimmedEmail) belum terdaftar di Supabase.',
        );
      }
      throw Exception('Akun ($trimmedEmail) belum terdaftar! Silakan lakukan pendaftaran akun terlebih dahulu.');
    }

    final userMap = users[matchedIndex];
    if (userMap['password'] != trimmedPassword) {
      throw Exception('Kata sandi salah. Silakan periksa kembali kata sandi Anda.');
    }

    final user = UserModel.fromMap(userMap);
    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    await prefs.setString(authStorageKey, user.toJson());

    // Coba daftarkan otomatis ke Supabase di latar belakang agar akun tersinkron
    if (sbClient != null) {
      try {
        await sbClient.auth.signUp(
          email: trimmedEmail,
          password: trimmedPassword,
          data: {'nama': user.nama},
        );
      } catch (_) {}
    }

    state = AsyncValue.data(user);
  }

  /// Login via Gmail / Google
  Future<void> loginWithGoogle(String email) async {
    final trimmedEmail = email.trim().toLowerCase();

    final sbClient = SupabaseService.client;
    if (sbClient != null) {
      try {
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

    await Future.delayed(const Duration(milliseconds: 200));
    final users = await getRegisteredUsers();
    final matchedIndex = users.indexWhere(
      (u) => (u['email'] as String? ?? '').toLowerCase() == trimmedEmail,
    );

    if (matchedIndex == -1) {
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
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();
    final trimmedNama = nama.trim();

    final prefs = ref.watch(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    final users = await getRegisteredUsers();
    final exists = users.any(
      (u) => (u['email'] as String? ?? '').toLowerCase() == trimmedEmail,
    );

    if (exists) {
      throw Exception('Email ($trimmedEmail) sudah terdaftar. Silakan langsung masuk (login).');
    }

    String generatedId = 'usr-${DateTime.now().millisecondsSinceEpoch}';

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
          generatedId = sbUser.id;
        }
      } catch (e) {
        debugPrint('⚠️ [Supabase Auth] SignUp cloud info: $e');
      }
    }

    final newUserMap = {
      'id': generatedId,
      'nama': trimmedNama,
      'email': trimmedEmail,
      'password': trimmedPassword,
      'createdAt': DateTime.now().toIso8601String(),
      'isGuest': false,
    };

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

    // Tidak ada notifikasi bawaan dummy, mulai dari daftar kosong
    return [];
  }

  Future<void> addNotification(ServiceNotification notification) async {
    if (state.hasValue) {
      final current = state.value!;
      final updated = [notification, ...current];
      state = AsyncValue.data(updated);
      _persist(updated);
    }
  }

  /// Mengevaluasi riwayat servis & komponen untuk menghasilkan notifikasi otomatis
  Future<void> evaluateServiceReminders(
    List<ServiceHistory> historyList,
    List<ServiceComponent> components, {
    ServiceHistory? newlyAddedService,
  }) async {
    final perm = ref.read(notificationPermissionProvider);
    if (perm != NotificationPermissionStatus.granted) return;

    final currentList = List<ServiceNotification>.from(state.value ?? []);
    final List<ServiceNotification> newNotifications = [];

    // 1. Notifikasi pencatatan servis baru
    if (newlyAddedService != null) {
      final matchedComp = components.where(
        (c) => newlyAddedService.jenisServis.toLowerCase().contains(c.nama.toLowerCase()),
      );
      final nextKmText = matchedComp.isNotEmpty
          ? ' Jadwal ${matchedComp.first.nama} berikutnya pada ${newlyAddedService.odometer + matchedComp.first.intervalKm} km.'
          : '';

      newNotifications.add(
        ServiceNotification(
          id: 'notif-add-${newlyAddedService.id}',
          title: '✅ Servis ${newlyAddedService.jenisServis} Tercatat',
          message:
              'Servis pada odometer ${newlyAddedService.odometer} km berhasil disimpan.$nextKmText',
          timestamp: DateTime.now(),
          isRead: false,
          type: 'success',
          componentName: matchedComp.isNotEmpty ? matchedComp.first.nama : newlyAddedService.jenisServis,
          isUrgent: false,
        ),
      );
    }

    // 2. Evaluasi kondisi semua komponen terhadap odometer tertinggi saat ini
    if (historyList.isNotEmpty) {
      final int currentOdo = historyList
          .map((e) => e.odometer)
          .reduce((a, b) => a > b ? a : b);

      for (final comp in components) {
        final related = historyList
            .where(
              (s) =>
                  s.status == 'Selesai' &&
                  s.jenisServis.toLowerCase().contains(comp.nama.toLowerCase()),
            )
            .toList();
        final int lastServicedKm = related.isNotEmpty ? related.first.odometer : 0;
        final int nextServiceKm = lastServicedKm > 0
            ? (lastServicedKm + comp.intervalKm)
            : comp.intervalKm;
        final int kmRemaining = nextServiceKm > currentOdo ? (nextServiceKm - currentOdo) : 0;

        if (currentOdo >= nextServiceKm && currentOdo > 0) {
          final overdueId = 'notif-overdue-${comp.id}-$nextServiceKm';
          final alreadyExists = currentList.any((n) => n.id == overdueId) ||
              newNotifications.any((n) => n.id == overdueId);
          if (!alreadyExists) {
            newNotifications.add(
              ServiceNotification(
                id: overdueId,
                title: '🚨 Waktunya Servis ${comp.nama}!',
                message:
                    'Odometer saat ini ($currentOdo km) telah melewati jadwal servis ${comp.nama} ($nextServiceKm km). Segera lakukan pengecekan/penggantian.',
                timestamp: DateTime.now(),
                isRead: false,
                type: 'warning',
                componentName: comp.nama,
                isUrgent: true,
              ),
            );
          }
        } else if (kmRemaining > 0 && kmRemaining <= 500 && currentOdo > 0) {
          final warnId = 'notif-warn-${comp.id}-$nextServiceKm';
          final alreadyExists = currentList.any((n) => n.id == warnId) ||
              newNotifications.any((n) => n.id == warnId);
          if (!alreadyExists) {
            newNotifications.add(
              ServiceNotification(
                id: warnId,
                title: '⏳ Pengingat Servis: ${comp.nama}',
                message:
                    'Jadwal servis ${comp.nama} tinggal $kmRemaining km lagi (target: $nextServiceKm km). Siapkan jadwal perawatan motor Anda.',
                timestamp: DateTime.now(),
                isRead: false,
                type: 'reminder',
                componentName: comp.nama,
                isUrgent: false,
              ),
            );
          }
        }
      }
    }

    if (newNotifications.isNotEmpty) {
      final updated = [...newNotifications, ...currentList];
      state = AsyncValue.data(updated);
      await _persist(updated);
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

  // Default coordinate: Balikpapan, Kalimantan Timur
  static const defaultLocation = LocationState(
    permission: LocationPermissionState.granted,
    latitude: -1.2379,
    longitude: 116.8529,
    locationName: 'Balikpapan, Kalimantan Timur (GPS Aktif)',
  );
}

class LocationNotifier extends Notifier<LocationState> {
  static const String locationStorageKey = 'servisku_user_location_v2';

  @override
  LocationState build() {
    Future.microtask(() => detectRealLocation(useSavedIfAvailable: true));
    return LocationState.defaultLocation;
  }

  Future<void> _saveLocation(double lat, double lng, String name) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
      await prefs.setString(
        locationStorageKey,
        json.encode({'lat': lat, 'lng': lng, 'name': name}),
      );
    } catch (_) {}
  }

  /// Mengubah koordinat GPS (lat, lng) menjadi nama Kota & Provinsi yang bersih via BigDataCloud API
  Future<String> _reverseGeocodeClean(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=id',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final locality = data['locality']?.toString() ?? '';
        final city = data['city']?.toString() ?? '';
        final province = data['principalSubdivision']?.toString() ?? '';

        final primary = city.isNotEmpty ? city : locality;
        final parts = [primary, province]
            .where((s) => s.trim().isNotEmpty)
            .toSet()
            .toList();
        if (parts.isNotEmpty) {
          return '${parts.join(', ')} (GPS Aktif)';
        }
      }
    } catch (_) {}
    return 'Titik GPS (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  /// Mendeteksi lokasi pengguna secara presisi menggunakan HTML5 Browser GPS (navigator.geolocation)
  Future<void> detectRealLocation({bool useSavedIfAvailable = false}) async {
    if (useSavedIfAvailable) {
      try {
        final prefs = ref.read(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
        final saved = prefs.getString(locationStorageKey);
        if (saved != null && saved.isNotEmpty) {
          final map = json.decode(saved) as Map<String, dynamic>;
          final lat = (map['lat'] as num).toDouble();
          final lng = (map['lng'] as num).toDouble();
          final name = map['name']?.toString() ?? '';
          if (name.isNotEmpty && !name.startsWith('Mendeteksi') && !name.startsWith('Mencari')) {
            state = LocationState(
              permission: LocationPermissionState.granted,
              latitude: lat,
              longitude: lng,
              locationName: name,
            );
            return;
          }
        }
      } catch (_) {}
    }

    // Ambil koordinat GPS asli dari perangkat/browser (navigator.geolocation)
    final gpsPos = await getBrowserGpsPosition();
    if (gpsPos != null) {
      final cleanName = await _reverseGeocodeClean(gpsPos.lat, gpsPos.lng);
      state = LocationState(
        permission: LocationPermissionState.granted,
        latitude: gpsPos.lat,
        longitude: gpsPos.lng,
        locationName: cleanName,
      );
      await _saveLocation(gpsPos.lat, gpsPos.lng, cleanName);
      return;
    }

    // Jika GPS browser belum diizinkan, gunakan lokasi tersimpan atau default yang bersih
    state = LocationState(
      permission: LocationPermissionState.granted,
      latitude: state.latitude,
      longitude: state.longitude,
      locationName: state.locationName,
    );
  }

  /// Mencari dan mengatur titik koordinat berdasarkan nama Kota / Kecamatan
  Future<bool> searchAndSetLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;

    // 1. Cek daftar kota utama Indonesia (instan & 100% akurat)
    for (final entry in Workshop.indonesiaCities.entries) {
      if (entry.key.toLowerCase() == trimmed.toLowerCase() ||
          entry.value.fullName.toLowerCase().contains(trimmed.toLowerCase())) {
        final label = '${entry.value.fullName} (GPS Aktif)';
        state = LocationState(
          permission: LocationPermissionState.granted,
          latitude: entry.value.lat,
          longitude: entry.value.lng,
          locationName: label,
        );
        await _saveLocation(entry.value.lat, entry.value.lng, label);
        return true;
      }
    }

    // 2. Geocode via OpenStreetMap Nominatim untuk kecamatan/kota lainnya
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(trimmed)}&countrycodes=id&limit=1&accept-language=id',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final List<dynamic> results = json.decode(res.body) as List<dynamic>;
        if (results.isNotEmpty) {
          final item = results.first as Map<String, dynamic>;
          final double lat = double.parse(item['lat'].toString());
          final double lng = double.parse(item['lon'].toString());
          final cleanName = await _reverseGeocodeClean(lat, lng);

          state = LocationState(
            permission: LocationPermissionState.granted,
            latitude: lat,
            longitude: lng,
            locationName: cleanName,
          );
          await _saveLocation(lat, lng, cleanName);
          return true;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Location] Pencarian gagal: $e');
    }

    final fallbackName = '$trimmed (GPS Aktif)';
    state = LocationState(
      permission: LocationPermissionState.granted,
      latitude: state.latitude,
      longitude: state.longitude,
      locationName: fallbackName,
    );
    await _saveLocation(state.latitude, state.longitude, fallbackName);
    return true;
  }

  void requestPermission() {
    state = LocationState(
      permission: LocationPermissionState.requesting,
      latitude: state.latitude,
      longitude: state.longitude,
      locationName: state.locationName,
    );
  }

  void grantPermission({double? lat, double? lng, String? locName}) {
    final newLat = lat ?? state.latitude;
    final newLng = lng ?? state.longitude;
    final newName = locName ?? state.locationName;
    state = LocationState(
      permission: LocationPermissionState.granted,
      latitude: newLat,
      longitude: newLng,
      locationName: newName,
    );
    _saveLocation(newLat, newLng, newName);
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

// List bengkel terdekat yang diurutkan secara dinamis mengikuti lokasi pengguna
final nearbyWorkshopsProvider = Provider<List<Workshop>>((ref) {
  final location = ref.watch(locationProvider);
  final category = ref.watch(workshopFilterCategoryProvider);
  final search = ref.watch(workshopSearchQueryProvider).toLowerCase();

  var list = Workshop.generateForLocation(
    location.latitude,
    location.longitude,
    location.locationName,
  );

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
