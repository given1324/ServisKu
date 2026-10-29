import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workshop_model.dart';
import '../providers/service_provider.dart';

/// Layar Pencari Bengkel Terdekat Berdasarkan Google Maps (MVP Advance Feature 3)
class WorkshopMapScreen extends ConsumerStatefulWidget {
  const WorkshopMapScreen({super.key});

  @override
  ConsumerState<WorkshopMapScreen> createState() => _WorkshopMapScreenState();
}

class _WorkshopMapScreenState extends ConsumerState<WorkshopMapScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLocationPermissionDialog() {
    ref.read(locationProvider.notifier).requestPermission();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Color(0xFF135A4B)),
            SizedBox(width: 10),
            Text('Izin Akses Lokasi (GPS)', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ServisKu membutuhkan akses lokasi Anda untuk menampilkan bengkel resmi (AHASS, Yamaha) dan bengkel umum terdekat secara presisi di Google Maps.',
              style: TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              '• Menghitung jarak tempuh akurat (km)\n• Membuka navigasi rute ke bengkel\n• Siaga tambal ban dan bengkel 24 jam',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(locationProvider.notifier).cancelPermission();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permintaan lokasi dibatalkan. Menampilkan bengkel berdasarkan area default.'),
                ),
              );
            },
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(locationProvider.notifier).denyPermission();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text('Izin lokasi ditolak. Gunakan tombol Coba Lagi untuk mengaktifkan.'),
                ),
              );
            },
            child: const Text('Tolak', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135A4B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(locationProvider.notifier).grantPermission(
                    lat: -6.2550,
                    lng: 106.6200,
                    locName: 'Gading Serpong, Tangerang Selatan (GPS Aktif)',
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF135A4B),
                  content: Text('Lokasi GPS berhasil diaktifkan! Menampilkan bengkel terdekat.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              );
            },
            child: const Text('Izinkan Lokasi'),
          ),
        ],
      ),
    );
  }

  void _showGoogleMapsModal(Workshop workshop, double userLat, double userLng) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final searchUrl = workshop.getGoogleMapsSearchUrl();
        final routeUrl = workshop.getGoogleMapsDirectionUrl(userLat, userLng);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F2EF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.map_rounded, color: Color(0xFF135A4B), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workshop.nama,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          workshop.alamat,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Jarak dari Posisi Anda:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text('${workshop.hitungJarak(userLat, userLng)} km',
                            style: const TextStyle(color: Color(0xFF135A4B), fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Jam Operasional:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text(workshop.jamBuka,
                            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135A4B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Buka Rute di Google Maps', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showLinkDialog('Rute Navigasi Google Maps', routeUrl);
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF135A4B),
                  side: const BorderSide(color: Color(0xFF135A4B)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Buka Profil Bengkel di Google Maps'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showLinkDialog('Pencarian Google Maps', searchUrl);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLinkDialog(String title, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aplikasi siap membuka tautan Google Maps berikut di browser atau aplikasi Google Maps:',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(color: Color(0xFF135A4B), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135A4B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF7F9F9);
    const accentColor = Color(0xFF135A4B);

    final locationState = ref.watch(locationProvider);
    final workshops = ref.watch(nearbyWorkshopsProvider);
    final selectedCategory = ref.watch(workshopFilterCategoryProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bengkel & Peta Google Maps',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Perbarui Lokasi GPS',
            icon: const Icon(Icons.my_location_rounded, color: Colors.white),
            onPressed: _showLocationPermissionDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Status Izin Lokasi & GPS (Permission Handling)
          if (locationState.permission != LocationPermissionState.granted)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade700),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_rounded, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationState.permission == LocationPermissionState.denied
                              ? 'Izin Lokasi Ditolak'
                              : 'Permintaan Lokasi Dibatalkan',
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          locationState.errorMessage ?? 'Menggunakan lokasi acuan default Serpong, Tangerang.',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135A4B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: _showLocationPermissionDialog,
                    child: const Text('Coba Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Peta Visualisasi Mini (Google Maps Radar Container)
          Container(
            height: 140,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Stack(
              children: [
                // Grid background lines
                CustomPaint(
                  size: const Size(double.infinity, 140),
                  painter: _MapGridPainter(),
                ),

                // Center Pulsing User Location Marker
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF135A4B).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFF135A4B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF135A4B).withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Posisi Anda Saat Ini',
                          style: TextStyle(color: Color(0xFF135A4B), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // Workshop Pins simulation
                Positioned(
                  top: 25,
                  left: 40,
                  child: _buildMapPin('AHASS', Colors.red.shade700),
                ),
                Positioned(
                  bottom: 25,
                  right: 50,
                  child: _buildMapPin('Yamaha', Colors.blue.shade700),
                ),
                Positioned(
                  top: 30,
                  right: 80,
                  child: _buildMapPin('24 Jam', accentColor),
                ),

                // Info overlay
                Positioned(
                  bottom: 8,
                  left: 12,
                  child: Row(
                    children: [
                      const Icon(Icons.near_me, color: Color(0xFF64748B), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        locationState.locationName,
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari nama bengkel, alamat, atau AHASS...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(workshopSearchQueryProvider.notifier).setQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) {
                ref.read(workshopSearchQueryProvider.notifier).setQuery(val);
              },
            ),
          ),

          // Kategori Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildCategoryChip('Semua', selectedCategory),
                const SizedBox(width: 8),
                _buildCategoryChip('Resmi Honda', selectedCategory),
                const SizedBox(width: 8),
                _buildCategoryChip('Resmi Yamaha', selectedCategory),
                const SizedBox(width: 8),
                _buildCategoryChip('Bengkel Umum', selectedCategory),
                const SizedBox(width: 8),
                _buildCategoryChip('Tambal Ban', selectedCategory),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Daftar Bengkel Terdekat (Empty State & Cards)
          Expanded(
            child: workshops.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, color: Colors.grey, size: 48),
                        const SizedBox(height: 10),
                        const Text('Tidak ada bengkel yang sesuai filter',
                            style: TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            ref.read(workshopSearchQueryProvider.notifier).setQuery('');
                            ref.read(workshopFilterCategoryProvider.notifier).setCategory('Semua');
                          },
                          child: const Text('Reset Filter Pencarian'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: workshops.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final item = workshops[index];
                      final distance = item.hitungJarak(locationState.latitude, locationState.longitude);

                      return _buildWorkshopCard(item, distance, locationState.latitude, locationState.longitude);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(String label, Color color) {
    return Column(
      children: [
        Icon(Icons.location_on, color: color, size: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String selected) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () {
        ref.read(workshopFilterCategoryProvider.notifier).setCategory(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF135A4B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF135A4B) : const Color(0xFFCBD5E1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkshopCard(Workshop item, double distance, double userLat, double userLng) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.isOfficial) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4F2EF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF135A4B), width: 0.8),
                            ),
                            child: const Text('RESMI',
                                style: TextStyle(
                                    color: Color(0xFF135A4B), fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          item.kategori,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.nama,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              // Jarak Km Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F2EF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF135A4B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.navigation_rounded, color: Color(0xFF135A4B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$distance km',
                      style: const TextStyle(
                        color: Color(0xFF135A4B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.alamat,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '${item.rating} (${item.totalUlasan} ulasan)',
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.access_time_rounded, color: Color(0xFF135A4B), size: 14),
              const SizedBox(width: 4),
              Text(
                item.jamBuka,
                style: const TextStyle(color: Color(0xFF135A4B), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135A4B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: const Text('Buka di Google Maps',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showGoogleMapsModal(item, userLat, userLng),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.6)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += 30) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
