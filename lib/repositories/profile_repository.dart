import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_info.dart';
import '../services/supabase_service.dart';

/// Repository khusus untuk mengelola request API (Supabase Cloud) dan
/// penyimpanan lokal profil kendaraan (VehicleInfo).
/// Memisahkan tanggung jawab request API dari UI (ProfileForm).
class ProfileRepository {
  static const String vehicleStorageKey = 'servisku_vehicle_info_v1';

  final SharedPreferences? prefs;

  ProfileRepository({this.prefs});

  SupabaseClient? get _supabase => SupabaseService.client;
  String? get _currentUserId => _supabase?.auth.currentUser?.id;
  String? get _currentUserEmail => _supabase?.auth.currentUser?.email;

  Future<SharedPreferences> _getPrefs() async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.reload();
    return p;
  }

  /// Memuat profil kendaraan dari Cloud API (Supabase) dengan fallback ke cache lokal.
  Future<VehicleInfo> fetchVehicleInfo([String? userEmail]) async {
    final cloudVehicle = await _fetchVehicleFromCloud(userEmail);
    if (cloudVehicle != null) {
      await _saveVehicleToLocal(cloudVehicle);
      return cloudVehicle;
    }
    return _fetchVehicleFromLocal();
  }

  /// Menyimpan profil kendaraan ke Cloud API (Supabase) dan cache lokal.
  Future<void> saveVehicleInfo(VehicleInfo info, [String? userEmail]) async {
    await _saveVehicleToCloud(info, userEmail);
    await _saveVehicleToLocal(info);
  }

  // ===========================================================================
  // FUNGSI KECIL FOKUS PADA REQUEST API & MAPPING (Single Responsibility)
  // ===========================================================================

  /// Mengambil data profil kendaraan dari tabel `vehicle_info` di Supabase.
  Future<VehicleInfo?> _fetchVehicleFromCloud([String? userEmail]) async {
    if (_supabase == null) return null;

    try {
      var query = _supabase!.from('vehicle_info').select();
      final email = userEmail ?? _currentUserEmail;
      if (email != null && email.isNotEmpty) {
        query = query.eq('user_email', email);
      }
      final response = await query.limit(1);
      if (response.isNotEmpty) {
        return mapCloudRowToVehicle(Map<String, dynamic>.from(response.first));
      }
    } catch (e) {
      debugPrint('⚠️ [Supabase] Gagal memuat info motor dari cloud: $e');
    }
    return null;
  }

  /// Mengirim request upsert profil kendaraan ke tabel `vehicle_info` di Supabase.
  Future<void> _saveVehicleToCloud(VehicleInfo info, [String? userEmail]) async {
    if (_supabase == null) return;

    try {
      final email = userEmail ?? _currentUserEmail ?? 'user@servisku.id';
      final payload = buildVehiclePayload(
        info: info,
        userEmail: email,
        userId: _currentUserId,
      );
      await _supabase!.from('vehicle_info').upsert(payload);
      debugPrint('✅ [Supabase] Info motor tersimpan di cloud');
    } catch (e) {
      debugPrint('⚠️ [Supabase] Gagal menyimpan info motor ke cloud: $e');
    }
  }

  /// Membaca profil kendaraan dari SharedPreferences lokal.
  Future<VehicleInfo> _fetchVehicleFromLocal() async {
    final p = await _getPrefs();
    final jsonString = p.getString(vehicleStorageKey);
    if (jsonString == null || jsonString.trim().isEmpty) {
      return VehicleInfo.defaultVehicle;
    }
    try {
      return VehicleInfo.fromJson(jsonString);
    } catch (_) {
      return VehicleInfo.defaultVehicle;
    }
  }

  /// Menyimpan profil kendaraan ke SharedPreferences lokal.
  Future<void> _saveVehicleToLocal(VehicleInfo info) async {
    final p = await _getPrefs();
    await p.setString(vehicleStorageKey, info.toJson());
  }

  /// Memetakan baris respons API/Supabase menjadi objek [VehicleInfo].
  static VehicleInfo mapCloudRowToVehicle(Map<String, dynamic> item) {
    return VehicleInfo(
      namaMotor: item['nama_motor']?.toString() ?? VehicleInfo.defaultVehicle.namaMotor,
      platNomor: item['plat_nomor']?.toString() ?? VehicleInfo.defaultVehicle.platNomor,
      tahun: (item['tahun'] as num?)?.toInt() ?? VehicleInfo.defaultVehicle.tahun,
    );
  }

  /// Menyusun payload JSON untuk request API penyimpanan profil kendaraan.
  static Map<String, dynamic> buildVehiclePayload({
    required VehicleInfo info,
    required String userEmail,
    String? userId,
  }) {
    final payload = <String, dynamic>{
      'user_email': userEmail,
      'nama_motor': info.namaMotor,
      'plat_nomor': info.platNomor,
      'tahun': info.tahun,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (userId != null && userId.isNotEmpty) {
      payload['user_id'] = userId;
    }
    return payload;
  }
}

