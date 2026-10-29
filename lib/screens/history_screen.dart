import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/service_history.dart';
import '../providers/service_provider.dart';
import 'form_service_screen.dart';

/// Layar Daftar Riwayat Servis Lengkap (CRUD, Pencarian, Ringkasan Biaya)
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(ServiceHistory service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Catatan Servis',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan servis "${service.jenisServis}"?',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(serviceHistoryProvider.notifier).deleteService(service.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text('Catatan servis berhasil dihapus'),
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF7F9F9);
    const cardColor = Colors.white;
    const accentColor = Color(0xFF135A4B);

    final historyState = ref.watch(serviceHistoryProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Riwayat Perawatan Servis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah Servis Baru',
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                  child: const FormServisScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: historyState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Terjadi kesalahan saat memuat data.\n$err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => ref.read(serviceHistoryProvider.notifier).refreshData(),
                child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        data: (allServices) {
          // Hitung total pengeluaran bulan ini
          final now = DateTime.now();
          final currentMonthServices = allServices.where((s) =>
              s.createdAt.month == now.month && s.createdAt.year == now.year);
          final int totalBulanIni = currentMonthServices.fold<int>(
              0, (sum, item) => sum + item.totalBiaya);

          // Filter pencarian
          final filteredServices = _searchQuery.isEmpty
              ? allServices
              : allServices.where((s) {
                  final q = _searchQuery.toLowerCase();
                  return s.jenisServis.toLowerCase().contains(q) ||
                      (s.catatan != null && s.catatan!.toLowerCase().contains(q));
                }).toList();

          return Column(
            children: [
              // Ringkasan Pengeluaran Bulan Ini
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE4F2EF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengeluaran Servis Bulan Ini (${DateFormat('MMMM yyyy').format(now)})',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                                .format(totalBulanIni),
                            style: const TextStyle(
                              color: Color(0xFF135A4B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F2EF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${currentMonthServices.length} Servis',
                        style: const TextStyle(
                          color: Color(0xFF135A4B),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat servis (misal: Kampas Rem, Oli)...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF135A4B), width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                ),
              ),

              // List View Servis
              Expanded(
                child: filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_toggle_off_rounded, size: 54, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada riwayat servis. Silakan tambah data baru.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Catat Servis Pertama', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => Padding(
                                    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                                    child: const FormServisScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: accentColor,
                        onRefresh: () async {
                          await ref.read(serviceHistoryProvider.notifier).refreshData();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredServices.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (ctx, index) {
                            final item = filteredServices[index];
                            return _buildServiceCard(item);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(ServiceHistory item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
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
                    Text(
                      item.jenisServis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(item.createdAt),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Color(0xFF64748B)),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                        child: FormServisScreen(existingService: item),
                      ),
                    );
                  } else if (val == 'delete') {
                    _showDeleteDialog(item);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: Color(0xFF1E293B), size: 18),
                        SizedBox(width: 8),
                        Text('Edit Catatan', style: TextStyle(color: Color(0xFF1E293B))),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Hapus Catatan', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Odometer Servis', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      '${NumberFormat.decimalPattern().format(item.odometer)} km',
                      style: const TextStyle(color: Color(0xFF135A4B), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Biaya', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.totalBiaya),
                      style: const TextStyle(color: Color(0xFF135A4B), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (item.catatan != null && item.catatan!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.catatan!,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
