import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_history.dart';
import '../models/service_component.dart';
import '../models/vehicle_info.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

class ServiceRepository {
  static const String storageKey = 'servisku_service_history_v1';
  static const String vehicleStorageKey = 'servisku_vehicle_info_v1';
  static const String componentsStorageKey = 'servisku_service_components_v1';

  final SharedPreferences? prefs;
  final ApiService? apiService;

  ServiceRepository({this.prefs, this.apiService});

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

  Future<List<ServiceHistory>> _fetchLocalList(SharedPreferences p) async {
    final jsonString = p.getString(storageKey);
    if (jsonString == null || jsonString.trim().isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      final list = decoded
          .map((item) => ServiceHistory.fromMap(item as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Memuat daftar riwayat servis dari Supabase PostgreSQL dengan RLS & fallback lokal
  Future<List<ServiceHistory>> fetchServiceHistory([String? userEmail]) async {
    if (_supabase != null) {
      try {
        var query = _supabase!.from('service_history').select();
        // RLS Supabase secara otomatis memfilter baris berdasarkan user_id token aktif,
        // namun kita juga dapat memfilter eksplisit jika user_email disertakan
        final email = userEmail ?? _currentUserEmail;
        if (email != null && email.isNotEmpty) {
          query = query.eq('user_email', email);
        }
        final response = await query.order('created_at', ascending: false);
        final list = (response as List).map((item) {
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
        }).toList();

        final p = await _getPrefs();
        await _saveList(p, list);
        debugPrint('✅ [Supabase] Berhasil memuat ${list.length} riwayat servis dari cloud');
        return list;
      } catch (e) {
        debugPrint('⚠️ [Supabase] Gagal memuat dari Supabase, menggunakan cache lokal: $e');
      }
    }

    if (apiService != null) {
      try {
        final list = await apiService!.fetchServices();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (prefs != null) {
          await _saveList(prefs!, list);
        }
        return list;
      } catch (_) {}
    }

    final p = await _getPrefs();
    return _fetchLocalList(p);
  }

  /// Menambahkan riwayat servis baru ke Supabase PostgreSQL & cache lokal
  Future<void> addServiceHistory(ServiceHistory service, [String? userEmail]) async {
    if (_supabase != null) {
      try {
        final email = userEmail ?? _currentUserEmail ?? 'user@servisku.id';
        final payload = {
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
        debugPrint('✅ [Supabase] Riwayat servis ${service.jenisServis} tersimpan di cloud');
      } catch (e) {
        debugPrint('⚠️ [Supabase] Gagal menyimpan riwayat ke cloud: $e');
      }
    }

    if (apiService != null) {
      try {
        await apiService!.createService(service);
      } catch (_) {}
    }

    final p = await _getPrefs();
    final currentList = await _fetchLocalList(p);
    currentList.removeWhere((item) => item.id == service.id);
    currentList.insert(0, service);
    await _saveList(p, currentList);
  }

  /// Memperbarui riwayat servis di Supabase PostgreSQL & cache lokal
  Future<void> updateServiceHistory(ServiceHistory service, [String? userEmail]) async {
    if (_supabase != null) {
      try {
        await _supabase!.from('service_history').update({
          'jenis_servis': service.jenisServis,
          'odometer': service.odometer,
          'total_biaya': service.totalBiaya,
          'status': service.status,
          'catatan': service.catatan,
        }).eq('id', service.id);
        debugPrint('✅ [Supabase] Riwayat servis ID ${service.id} berhasil diperbarui di cloud');
      } catch (e) {
        debugPrint('⚠️ [Supabase] Gagal update riwayat di cloud: $e');
      }
    }

    if (apiService != null) {
      try {
        await apiService!.updateService(service);
      } catch (_) {}
    }

    final p = await _getPrefs();
    final currentList = await _fetchLocalList(p);
    final index = currentList.indexWhere((item) => item.id == service.id);
    if (index != -1) {
      currentList[index] = service;
      await _saveList(p, currentList);
    }
  }

  /// Menghapus riwayat servis dari Supabase PostgreSQL & cache lokal
  Future<void> deleteServiceHistory(String id) async {
    if (_supabase != null) {
      try {
        await _supabase!.from('service_history').delete().eq('id', id);
        debugPrint('✅ [Supabase] Riwayat ID $id berhasil dihapus dari cloud');
      } catch (e) {
        debugPrint('⚠️ [Supabase] Gagal menghapus riwayat dari cloud: $e');
      }
    }

    if (apiService != null) {
      try {
        await apiService!.deleteService(id);
      } catch (_) {}
    }

    final p = await _getPrefs();
    final currentList = await _fetchLocalList(p);
    currentList.removeWhere((item) => item.id == id);
    await _saveList(p, currentList);
  }

  Future<void> _saveList(SharedPreferences prefs, List<ServiceHistory> list) async {
    final jsonList = list.map((item) => item.toMap()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(storageKey, jsonString);
  }

  // ===========================================================================
  // 2. PROFIL KENDARAAN (Vehicle Info)
  // ===========================================================================

  /// Memuat info motor dari Supabase PostgreSQL
  Future<VehicleInfo> fetchVehicleInfo([String? userEmail]) async {
    if (_supabase != null) {
      try {
        var query = _supabase!.from('vehicle_info').select();
        final email = userEmail ?? _currentUserEmail;
        if (email != null && email.isNotEmpty) {
          query = query.eq('user_email', email);
        }
        final response = await query.limit(1);
        if (response.isNotEmpty) {
          final item = response.first;
          final v = VehicleInfo(
            namaMotor: item['nama_motor']?.toString() ?? VehicleInfo.defaultVehicle.namaMotor,
            platNomor: item['plat_nomor']?.toString() ?? VehicleInfo.defaultVehicle.platNomor,
            tahun: (item['tahun'] as num?)?.toInt() ?? VehicleInfo.defaultVehicle.tahun,
          );
          final p = await _getPrefs();
          await p.setString(vehicleStorageKey, v.toJson());
          return v;
        }
      } catch (e) {
        debugPrint('⚠️ [Supabase] Gagal memuat info motor dari cloud: $e');
      }
    }

    final prefs = await _getPrefs();
    final jsonString = prefs.getString(vehicleStorageKey);
    if (jsonString == null || jsonString.trim().isEmpty) {
      return VehicleInfo.defaultVehicle;
    }
    try {
      return VehicleInfo.fromJson(jsonString);
    } catch (_) {
      return VehicleInfo.defaultVehicle;
    }
  }

  /// Menyimpan info motor ke Supabase PostgreSQL & lokal
  Future<void> saveVehicleInfo(VehicleInfo info, [String? userEmail]) async {
    if (_supabase != null) {
      try {
        final email = userEmail ?? _currentUserEmail ?? 'user@servisku.id';
        final payload = {
          'user_email': email,
          'nama_motor': info.namaMotor,
          'plat_nomor': info.platNomor,
          'tahun': info.tahun,
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (_currentUserId != null) {
          payload['user_id'] = _currentUserId!;
        }
        await _supabase!.from('vehicle_info').upsert(payload);
        debugPrint('✅ [Supabase] Info motor tersimpan di cloud');
      } catch (e) {
        debugPrint('⚠️ [Supabase] Gagal menyimpan info motor ke cloud: $e');
      }
    }

    final prefs = await _getPrefs();
    await prefs.setString(vehicleStorageKey, info.toJson());
  }

  // ===========================================================================
  // 3. KOMPONEN SERVIS (Service Components)
  // ===========================================================================

  /// Memuat komponen servis dari Supabase PostgreSQL
  Future<List<ServiceComponent>> fetchComponents([String? userEmail]) async {
    if (_supabase != null) {
      try {
        var query = _supabase!.from('service_components').select();
        final email = userEmail ?? _currentUserEmail;
        if (email != null && email.isNotEmpty) {
          query = query.eq('user_email', email);
        }
        final response = await query;
        if ((response as List).isNotEmpty) {
          final list = response.map((item) {
            return ServiceComponent(
              id: item['id']?.toString() ?? '',
              nama: item['nama']?.toString() ?? '',
              intervalKm: (item['interval_km'] as num?)?.toInt() ?? 2000,
              deskripsi: item['deskripsi']?.toString(),
              isCustom: item['is_custom'] == true,
            );
          }).toList();
          return list;
        }
      } catch (e) {
        debugPrint('⚠️ [Supabase] Gagal memuat komponen dari cloud: $e');
      }
    }

    final prefs = await _getPrefs();
    final jsonString = prefs.getString(componentsStorageKey);
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

  /// Tambah komponen servis ke Supabase
  Future<void> addComponent(ServiceComponent component, [String? userEmail]) async {
    if (_supabase != null) {
      try {
        final email = userEmail ?? _currentUserEmail ?? 'user@servisku.id';
        final payload = {
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
        debugPrint('✅ [Supabase] Komponen ${component.nama} tersimpan di cloud');
      } catch (e) {
        debugPrint('⚠️ [Supabase] Gagal tambah komponen di cloud: $e');
      }
    }

    final prefs = await _getPrefs();
    final currentList = await fetchComponents(userEmail);
    currentList.removeWhere((item) => item.id == component.id);
    currentList.add(component);
    final jsonList = currentList.map((item) => item.toMap()).toList();
    await prefs.setString(componentsStorageKey, json.encode(jsonList));
  }

  /// Update komponen servis di Supabase
  Future<void> updateComponent(ServiceComponent component, [String? userEmail]) async {
    if (_supabase != null) {
      try {
        await _supabase!.from('service_components').update({
          'nama': component.nama,
          'interval_km': component.intervalKm,
          'deskripsi': component.deskripsi,
        }).eq('id', component.id);
        debugPrint('✅ [Supabase] Komponen ${component.nama} diupdate di cloud');
      } catch (e) {
        debugPrint('⚠️ [Supabase] Gagal update komponen di cloud: $e');
      }
    }

    final prefs = await _getPrefs();
    final currentList = await fetchComponents(userEmail);
    final index = currentList.indexWhere((item) => item.id == component.id);
    if (index != -1) {
      currentList[index] = component;
      final jsonList = currentList.map((item) => item.toMap()).toList();
      await prefs.setString(componentsStorageKey, json.encode(jsonList));
    }
  }

  /// Hapus komponen servis dari Supabase
  Future<void> deleteComponent(String id) async {
    if (_supabase != null) {
      try {
        await _supabase!.from('service_components').delete().eq('id', id);
        debugPrint('✅ [Supabase] Komponen ID $id dihapus dari cloud');
      } catch (e) {
        debugPrint('⚠️ [Supabase] Gagal hapus komponen di cloud: $e');
      }
    }

    final prefs = await _getPrefs();
    final currentList = await fetchComponents();
    currentList.removeWhere((item) => item.id == id);
    final jsonList = currentList.map((item) => item.toMap()).toList();
    await prefs.setString(componentsStorageKey, json.encode(jsonList));
  }

  // Helper untuk reset/hapus semua data lokal
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(storageKey);
    await prefs.remove(vehicleStorageKey);
    await prefs.remove(componentsStorageKey);
  }
}
