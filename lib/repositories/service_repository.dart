import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_history.dart';
import '../models/service_component.dart';
import '../models/vehicle_info.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../utils/app_logger.dart';
import 'profile_repository.dart';

class ServiceRepository {
  static const String storageKey = 'servisku_service_history_v1';
  static const String vehicleStorageKey = ProfileRepository.vehicleStorageKey;
  static const String componentsStorageKey = 'servisku_service_components_v1';

  final SharedPreferences? prefs;
  final ApiService? apiService;
  final ProfileRepository _profileRepository;

  ServiceRepository({
    this.prefs,
    this.apiService,
    ProfileRepository? profileRepository,
  }) : _profileRepository = profileRepository ?? ProfileRepository(prefs: prefs);

  SupabaseClient? get _supabase => SupabaseService.client;
  String? get _currentUserId => _supabase?.auth.currentUser?.id;
  String? get _currentUserEmail => _supabase?.auth.currentUser?.email;

  Future<SharedPreferences> _getPrefs() async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.reload();
    return p;
  }

  // ===========================================================================
  // 1. RIWAYAT SERVIS (Service History)
  // ===========================================================================

  /// Memuat daftar riwayat servis dari Supabase PostgreSQL, REST API, atau cache lokal
  Future<List<ServiceHistory>> fetchServiceHistory() async {
    final cloudList = await _fetchHistoryFromCloud();
    if (cloudList != null) {
      final p = await _getPrefs();
      await _saveList(p, cloudList);
      return cloudList;
    }

    if (apiService != null) {
      final list = await apiService!.fetchServices();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (prefs != null) {
        await _saveList(prefs!, list);
      }
      return list;
    }

    final p = await _getPrefs();
    return _fetchLocalList(p);
  }

  /// Menambahkan riwayat servis baru ke Supabase PostgreSQL, REST API, & cache lokal
  Future<void> addServiceHistory(ServiceHistory service) async {
    await _upsertHistoryToCloud(service);

    if (apiService != null) {
      await apiService!.createService(service);
      if (prefs == null) return;
    }

    final p = await _getPrefs();
    final currentList = await _fetchLocalList(p);
    currentList.removeWhere((item) => item.id == service.id);
    currentList.insert(0, service);
    await _saveList(p, currentList);
  }

  /// Memperbarui riwayat servis di Supabase PostgreSQL, REST API, & cache lokal
  Future<void> updateServiceHistory(ServiceHistory service) async {
    await _updateHistoryInCloud(service);

    if (apiService != null) {
      await apiService!.updateService(service);
      if (prefs == null) return;
    }

    final p = await _getPrefs();
    final currentList = await _fetchLocalList(p);
    final index = currentList.indexWhere((item) => item.id == service.id);
    if (index != -1) {
      currentList[index] = service;
      await _saveList(p, currentList);
    }
  }

  /// Menghapus riwayat servis dari Supabase PostgreSQL, REST API, & cache lokal
  Future<void> deleteServiceHistory(String id) async {
    await _deleteHistoryFromCloud(id);

    if (apiService != null) {
      await apiService!.deleteService(id);
      if (prefs == null) return;
    }

    final p = await _getPrefs();
    final currentList = await _fetchLocalList(p);
    currentList.removeWhere((item) => item.id == id);
    await _saveList(p, currentList);
  }

  // --- Helper Riwayat Servis (Single Responsibility) ---

  Future<List<ServiceHistory>?> _fetchHistoryFromCloud([String? userEmail]) async {
    if (_supabase == null) return null;
    try {
      var query = _supabase!.from('service_history').select();
      final email = userEmail ?? _currentUserEmail;
      if (email != null && email.isNotEmpty) {
        query = query.eq('user_email', email);
      }
      final response = await query.order('created_at', ascending: false);
      final list = (response as List)
          .map((item) => _mapCloudRowToServiceHistory(Map<String, dynamic>.from(item)))
          .toList();
      AppLogger.success('SERVICE_REPO', 'Berhasil memuat ${list.length} riwayat servis dari Supabase cloud');
      return list;
    } catch (e) {
      AppLogger.warning('SERVICE_REPO', 'Gagal memuat dari Supabase, menggunakan cache lokal', error: e);
      return null;
    }
  }

  Future<void> _upsertHistoryToCloud(ServiceHistory service, [String? userEmail]) async {
    if (_supabase == null) return;
    try {
      final email = userEmail ?? _currentUserEmail ?? 'user@servisku.id';
      final payload = <String, dynamic>{
        'id': service.id,
        'user_email': email,
        'jenis_servis': service.jenisServis,
        'odometer': service.odometer,
        'total_biaya': service.totalBiaya,
        'status': service.status,
        'catatan': service.catatan,
        'created_at': service.createdAt.toIso8601String(),
      };
      if (_currentUserId != null) {
        payload['user_id'] = _currentUserId!;
      }
      await _supabase!.from('service_history').upsert(payload);
      AppLogger.success('SERVICE_REPO', 'Riwayat servis "${service.jenisServis}" (${service.odometer} km) tersimpan di cloud');
    } catch (e) {
      AppLogger.warning('SERVICE_REPO', 'Gagal menyimpan riwayat servis ke cloud', error: e);
    }
  }

  Future<void> _updateHistoryInCloud(ServiceHistory service) async {
    if (_supabase == null) return;
    try {
      await _supabase!.from('service_history').update({
        'jenis_servis': service.jenisServis,
        'odometer': service.odometer,
        'total_biaya': service.totalBiaya,
        'status': service.status,
        'catatan': service.catatan,
      }).eq('id', service.id);
      AppLogger.success('SERVICE_REPO', 'Riwayat servis ID ${service.id} diperbarui (status: ${service.status})');
    } catch (e) {
      AppLogger.warning('SERVICE_REPO', 'Gagal update riwayat servis ID ${service.id} di cloud', error: e);
    }
  }

  Future<void> _deleteHistoryFromCloud(String id) async {
    if (_supabase == null) return;
    try {
      await _supabase!.from('service_history').delete().eq('id', id);
      AppLogger.success('SERVICE_REPO', 'Riwayat servis ID $id dihapus dari cloud');
    } catch (e) {
      AppLogger.warning('SERVICE_REPO', 'Gagal menghapus riwayat ID $id dari cloud', error: e);
    }
  }

  ServiceHistory _mapCloudRowToServiceHistory(Map<String, dynamic> item) {
    return ServiceHistory(
      id: item['id']?.toString() ?? '',
      jenisServis: item['jenis_servis']?.toString() ?? '',
      odometer: (item['odometer'] as num?)?.toInt() ?? 0,
      totalBiaya: (item['total_biaya'] as num?)?.toInt() ?? 0,
      status: item['status']?.toString() ?? 'Selesai',
      catatan: item['catatan']?.toString(),
      createdAt: item['created_at'] != null
          ? DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Future<List<ServiceHistory>> _fetchLocalList(SharedPreferences p) async {
    final jsonString = p.getString(storageKey);
    if (jsonString == null || jsonString.trim().isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      final list = decoded
          .map((item) => ServiceHistory.fromMap(item as Map<String, dynamic>))
          .where((item) => !item.jenisServis.toLowerCase().contains('mock'))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveList(SharedPreferences prefs, List<ServiceHistory> list) async {
    final jsonList = list.map((item) => item.toMap()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(storageKey, jsonString);
  }

  // ===========================================================================
  // 2. PROFIL KENDARAAN (Vehicle Info -> Delegasi ke ProfileRepository)
  // ===========================================================================

  /// Memuat info motor melalui [ProfileRepository] (menghindari duplikasi kode)
  Future<VehicleInfo> fetchVehicleInfo() {
    return _profileRepository.fetchVehicleInfo();
  }

  /// Menyimpan info motor melalui [ProfileRepository] (menghindari duplikasi kode)
  Future<void> saveVehicleInfo(VehicleInfo info) {
    return _profileRepository.saveVehicleInfo(info);
  }

  // ===========================================================================
  // 3. KOMPONEN SERVIS (Service Components)
  // ===========================================================================

  /// Memuat komponen servis dari Supabase PostgreSQL atau cache lokal
  Future<List<ServiceComponent>> fetchComponents() async {
    final cloudComponents = await _fetchComponentsFromCloud();
    if (cloudComponents != null && cloudComponents.isNotEmpty) {
      return cloudComponents;
    }

    final p = await _getPrefs();
    return _fetchLocalComponents(p);
  }

  /// Tambah komponen servis ke Supabase & cache lokal
  Future<void> addComponent(ServiceComponent component) async {
    await _upsertComponentToCloud(component);

    final p = await _getPrefs();
    final currentList = await fetchComponents();
    currentList.removeWhere((item) => item.id == component.id);
    currentList.add(component);
    await _saveComponentsToLocal(p, currentList);
  }

  /// Update komponen servis di Supabase & cache lokal
  Future<void> updateComponent(ServiceComponent component) async {
    await _updateComponentInCloud(component);

    final p = await _getPrefs();
    final currentList = await fetchComponents();
    final index = currentList.indexWhere((item) => item.id == component.id);
    if (index != -1) {
      currentList[index] = component;
      await _saveComponentsToLocal(p, currentList);
    }
  }

  /// Hapus komponen servis dari Supabase & cache lokal
  Future<void> deleteComponent(String id) async {
    await _deleteComponentFromCloud(id);

    final p = await _getPrefs();
    final currentList = await fetchComponents();
    currentList.removeWhere((item) => item.id == id);
    await _saveComponentsToLocal(p, currentList);
  }

  // --- Helper Komponen Servis (Single Responsibility) ---

  Future<List<ServiceComponent>?> _fetchComponentsFromCloud([String? userEmail]) async {
    if (_supabase == null) return null;
    try {
      var query = _supabase!.from('service_components').select();
      final email = userEmail ?? _currentUserEmail;
      if (email != null && email.isNotEmpty) {
        query = query.eq('user_email', email);
      }
      final response = await query;
      if ((response as List).isNotEmpty) {
        return response.map((item) {
          return ServiceComponent(
            id: item['id']?.toString() ?? '',
            nama: item['nama']?.toString() ?? '',
            intervalKm: (item['interval_km'] as num?)?.toInt() ?? 2000,
            deskripsi: item['deskripsi']?.toString() ?? '',
            isCustom: item['is_custom'] == true,
          );
        }).toList();
      }
    } catch (e) {
      AppLogger.warning('COMPONENT_REPO', 'Gagal memuat komponen dari cloud', error: e);
    }
    return null;
  }

  Future<void> _upsertComponentToCloud(ServiceComponent component, [String? userEmail]) async {
    if (_supabase == null) return;
    try {
      final email = userEmail ?? _currentUserEmail ?? 'user@servisku.id';
      final payload = <String, dynamic>{
        'id': component.id,
        'user_email': email,
        'nama': component.nama,
        'interval_km': component.intervalKm,
        'deskripsi': component.deskripsi,
        'is_custom': component.isCustom,
      };
      if (_currentUserId != null) {
        payload['user_id'] = _currentUserId!;
      }
      await _supabase!.from('service_components').upsert(payload);
      AppLogger.success('COMPONENT_REPO', 'Komponen "${component.nama}" (${component.intervalKm} km) tersimpan di cloud');
    } catch (e) {
      AppLogger.warning('COMPONENT_REPO', 'Gagal tambah komponen di cloud', error: e);
    }
  }

  Future<void> _updateComponentInCloud(ServiceComponent component) async {
    if (_supabase == null) return;
    try {
      await _supabase!.from('service_components').update({
        'nama': component.nama,
        'interval_km': component.intervalKm,
        'deskripsi': component.deskripsi,
      }).eq('id', component.id);
      AppLogger.success('COMPONENT_REPO', 'Komponen "${component.nama}" diupdate di cloud');
    } catch (e) {
      AppLogger.warning('COMPONENT_REPO', 'Gagal update komponen di cloud', error: e);
    }
  }

  Future<void> _deleteComponentFromCloud(String id) async {
    if (_supabase == null) return;
    try {
      await _supabase!.from('service_components').delete().eq('id', id);
      AppLogger.success('COMPONENT_REPO', 'Komponen ID $id dihapus dari cloud');
    } catch (e) {
      AppLogger.warning('COMPONENT_REPO', 'Gagal hapus komponen di cloud', error: e);
    }
  }

  List<ServiceComponent> _fetchLocalComponents(SharedPreferences p) {
    final jsonString = p.getString(componentsStorageKey);
    if (jsonString == null || jsonString.trim().isEmpty) {
      return List<ServiceComponent>.from(ServiceComponent.defaultPresets);
    }
    try {
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => ServiceComponent.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List<ServiceComponent>.from(ServiceComponent.defaultPresets);
    }
  }

  Future<void> _saveComponentsToLocal(
    SharedPreferences p,
    List<ServiceComponent> list,
  ) async {
    final jsonList = list.map((item) => item.toMap()).toList();
    await p.setString(componentsStorageKey, json.encode(jsonList));
  }

  // Helper untuk reset/hapus semua data lokal
  Future<void> clearAll() async {
    final p = await _getPrefs();
    await p.remove(storageKey);
    await p.remove(vehicleStorageKey);
    await p.remove(componentsStorageKey);
  }
}
