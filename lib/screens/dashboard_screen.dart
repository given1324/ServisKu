import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_provider.dart';
import 'form_service_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceState = ref.watch(serviceHistoryProvider);
    
    // Helper to format currency
    final currencyFormatter = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F9),
      body: SafeArea(
        child: serviceState.when(
          // Kondisi 1: Initial loading di DashboardScreen
          loading: () => const Center(child: CircularProgressIndicator()),
          
          // Kondisi 4: Error state
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Terjadi kesalahan saat memuat data.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(serviceHistoryProvider.notifier).refreshData();
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
          
          // Data berhasil dimuat
          data: (data) {
            int totalPengeluaran = data.fold(0, (sum, item) => sum + item.totalBiaya);
            int totalServis = data.length;
            int lastOdometer = data.isEmpty ? 0 : data.map((e) => e.odometer).reduce((a, b) => a > b ? a : b);
            
            return RefreshIndicator(
              onRefresh: () async {
                await ref.read(serviceHistoryProvider.notifier).refreshData();
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Dark Green Header
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF135A4B),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                // Icon Circle
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                                  ),
                                  child: const Icon(
                                    Icons.pedal_bike,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'MOTOR UTAMA',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Honda Vario 160',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Odometer terakhir',
                                                style: TextStyle(color: Colors.white70, fontSize: 10),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${NumberFormat.decimalPattern().format(lastOdometer)} km',
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Servis terakhir',
                                                style: TextStyle(color: Colors.white70, fontSize: 10),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                data.isEmpty ? '-' : DateFormat('dd MMM yyyy').format(data.first.createdAt),
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Two Summary Cards
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE4F2EF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF2E8C78), size: 20),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('Total pengeluaran', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        currencyFormatter.format(totalPengeluaran), 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.history, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text('$totalServis kali servis', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFDF0E1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.speed_outlined, color: Color(0xFFD68A36), size: 20),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300, 
                                          borderRadius: BorderRadius.circular(4)
                                        ),
                                        child: const Text('Ganti oli mesin', style: TextStyle(fontSize: 10, color: Colors.black54)),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('42.000 km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: const LinearProgressIndicator(
                                          value: 0.8, 
                                          backgroundColor: Color(0xFFEEEEEE), 
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD68A36))
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('Sekitar 1.560 km lagi', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Riwayat Terbaru
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Riwayat terbaru',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Catatan servis kendaraanmu',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                              const Text(
                                'Lihat semua',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF135A4B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Cari jenis servis, misalnya kampas rem...',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  // Service List
                  data.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'Belum ada riwayat servis.\nSilakan tambah data baru.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final service = data[index];
                                
                                // Determine icon and colors based on type
                                IconData iconData = Icons.build_circle_outlined;
                                Color iconColor = const Color(0xFF2E8C78);
                                Color iconBgColor = const Color(0xFFE4F2EF);
                                
                                String lowerJenis = service.jenisServis.toLowerCase();
                                if (lowerJenis.contains('oli')) {
                                  iconData = Icons.account_balance_wallet_outlined;
                                  iconColor = const Color(0xFFD68A36);
                                  iconBgColor = const Color(0xFFFDF0E1);
                                } else if (lowerJenis.contains('rem')) {
                                  iconData = Icons.speed_outlined;
                                  iconColor = const Color(0xFF4B87AD);
                                  iconBgColor = const Color(0xFFE8F2F9);
                                }
                                
                                if (service.status == 'Selesai') {
                                  iconData = Icons.check;
                                  iconColor = const Color(0xFF2E8C78);
                                  iconBgColor = const Color(0xFFE4F2EF);
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: iconBgColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(iconData, color: iconColor),
                                    ),
                                    title: Text(
                                      service.jenisServis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF333333)),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          service.status == 'Selesai' && service.completedAt != null
                                              ? 'Diselesaikan pada ${DateFormat('dd MMM yyyy').format(service.completedAt!)}'
                                              : (service.status == 'Belum Selesai' ? 'Belum Selesai' : 'Selesai'),
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 10, color: Colors.grey.shade400),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('dd MMM yyyy').format(service.createdAt),
                                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                            const SizedBox(width: 8),
                                            Icon(Icons.speed, size: 10, color: Colors.grey.shade400),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${NumberFormat.decimalPattern().format(service.odometer)} km',
                                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: service.status == 'Belum Selesai' 
                                      ? PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_horiz, color: Colors.grey),
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.transparent,
                                                builder: (context) => Padding(
                                                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                                  child: FormServisScreen(existingService: service),
                                                ),
                                              );
                                            } else if (value == 'delete') {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Hapus Data'),
                                                  content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('Batal'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        ref.read(serviceHistoryProvider.notifier).deleteService(service.id);
                                                      },
                                                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Hapus', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        )
                                      : const Icon(Icons.more_horiz, color: Colors.grey),
                                  ),
                                );
                              },
                              childCount: data.length,
                            ),
                          ),
                        ),
                  
                  // Bottom spacing for FAB
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF135A4B),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: const FormServisScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
