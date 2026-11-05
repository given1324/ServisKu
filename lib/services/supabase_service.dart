import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi dan inisialisasi Supabase Client untuk ServisKu
class SupabaseService {
  static const String supabaseUrl = 'https://fscvegipvgxiqxbnhhde.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_gWj8TZ21MAXKn-z-pEkfBQ_KQMtjbK_';

  static bool isInitialized = false;

  /// Inisialisasi koneksi Supabase saat aplikasi pertama kali dijalankan
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      isInitialized = true;
      debugPrint('✅ [Supabase] Berhasil terhubung ke Supabase PostgreSQL: $supabaseUrl');
    } catch (e) {
      debugPrint('⚠️ [Supabase] Inisialisasi offline/gagal: $e');
    }
  }

  /// Klien Supabase aktif
  static SupabaseClient? get client {
    if (!isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}

