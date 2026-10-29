import 'dart:convert';
import 'dart:math';

/// Model Bengkel Motor untuk Fitur Pencari Bengkel Google Maps (MVP Advance Feature 3)
class Workshop {
  final String id;
  final String nama;
  final String kategori; // 'Resmi Honda', 'Resmi Yamaha', 'Bengkel Umum', 'Tambal Ban'
  final String alamat;
  final double latitude;
  final double longitude;
  final double rating;
  final int totalUlasan;
  final String jamBuka;
  final String nomorTelepon;
  final bool isOfficial;
  final bool isOpenNow;
  final double? customDistanceKm;

  const Workshop({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.totalUlasan,
    required this.jamBuka,
    required this.nomorTelepon,
    this.isOfficial = false,
    this.isOpenNow = true,
    this.customDistanceKm,
  });

  /// Menghitung jarak relatif (km) menggunakan rumus Haversine
  double hitungJarak(double userLat, double userLng) {
    if (customDistanceKm != null) return customDistanceKm!;
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(latitude - userLat);
    final dLng = _degreesToRadians(longitude - userLng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(userLat)) *
            cos(_degreesToRadians(latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return double.parse((earthRadius * c).toStringAsFixed(1));
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// URL resmi Google Maps untuk pencarian / navigasi
  String getGoogleMapsSearchUrl() {
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$nama $alamat')}';
  }

  /// URL resmi Google Maps untuk rute penunjuk arah langsung
  String getGoogleMapsDirectionUrl(double userLat, double userLng) {
    return 'https://www.google.com/maps/dir/?api=1&origin=$userLat,$userLng&destination=$latitude,$longitude';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'alamat': alamat,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'totalUlasan': totalUlasan,
      'jamBuka': jamBuka,
      'nomorTelepon': nomorTelepon,
      'isOfficial': isOfficial,
      'isOpenNow': isOpenNow,
    };
  }

  factory Workshop.fromMap(Map<String, dynamic> map) {
    return Workshop(
      id: map['id']?.toString() ?? '',
      nama: map['nama']?.toString() ?? 'Bengkel Motor',
      kategori: map['kategori']?.toString() ?? 'Bengkel Umum',
      alamat: map['alamat']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? -6.2570,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 106.6180,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      totalUlasan: (map['totalUlasan'] as num?)?.toInt() ?? 50,
      jamBuka: map['jamBuka']?.toString() ?? '08:00 - 17:00',
      nomorTelepon: map['nomorTelepon']?.toString() ?? '08123456789',
      isOfficial: map['isOfficial'] == true,
      isOpenNow: map['isOpenNow'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory Workshop.fromJson(String source) =>
      Workshop.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Preset daftar bengkel terdekat di sekitar lokasi pengguna (Tangerang / Serpong / Jakarta)
  static List<Workshop> defaultWorkshops = [
    const Workshop(
      id: 'ws-01',
      nama: 'AHASS 00123 Motor Honda Serpong',
      kategori: 'Resmi Honda',
      alamat: 'Jl. Raya Serpong Km 7 No. 12, Serpong',
      latitude: -6.2555,
      longitude: 106.6210,
      rating: 4.8,
      totalUlasan: 320,
      jamBuka: '07:30 - 17:00 (Buka)',
      nomorTelepon: '021-5374829',
      isOfficial: true,
      isOpenNow: true,
      customDistanceKm: 0.8,
    ),
    const Workshop(
      id: 'ws-02',
      nama: 'Yamaha Surya Motor Service Shop',
      kategori: 'Resmi Yamaha',
      alamat: 'Jl. Boulevard Gading Serpong Blok AA No. 5',
      latitude: -6.2420,
      longitude: 106.6280,
      rating: 4.7,
      totalUlasan: 184,
      jamBuka: '08:00 - 17:00 (Buka)',
      nomorTelepon: '021-5421980',
      isOfficial: true,
      isOpenNow: true,
      customDistanceKm: 1.4,
    ),
    const Workshop(
      id: 'ws-03',
      nama: 'Bengkel Motor Berkah Abadi 24 Jam',
      kategori: 'Bengkel Umum',
      alamat: 'Jl. Raya Kelapa Dua No. 45, Karawaci',
      latitude: -6.2380,
      longitude: 106.6110,
      rating: 4.6,
      totalUlasan: 95,
      jamBuka: 'Buka 24 Jam (Siaga Darurat)',
      nomorTelepon: '081389201928',
      isOfficial: false,
      isOpenNow: true,
      customDistanceKm: 2.1,
    ),
    const Workshop(
      id: 'ws-04',
      nama: 'Planet Ban & Servis Injeksi Cepat',
      kategori: 'Bengkel Umum',
      alamat: 'Jl. Pahlawan Seribu No. 9A, BSD City',
      latitude: -6.2750,
      longitude: 106.6620,
      rating: 4.9,
      totalUlasan: 412,
      jamBuka: '08:30 - 20:00 (Buka)',
      nomorTelepon: '021-5316278',
      isOfficial: false,
      isOpenNow: true,
      customDistanceKm: 3.5,
    ),
    const Workshop(
      id: 'ws-05',
      nama: 'Tambal Ban Tubeless & Press Velg Kang Ujang',
      kategori: 'Tambal Ban',
      alamat: 'Depan SPBU Pertamina Gading Serpong',
      latitude: -6.2510,
      longitude: 106.6195,
      rating: 4.5,
      totalUlasan: 48,
      jamBuka: 'Buka 24 Jam',
      nomorTelepon: '085712398471',
      isOfficial: false,
      isOpenNow: true,
      customDistanceKm: 0.5,
    ),
  ];
}
