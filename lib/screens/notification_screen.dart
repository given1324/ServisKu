import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/service_notification.dart';
import '../providers/service_provider.dart';

/// Layar Notifikasi & Pengingat Servis Berkala (MVP Advance Feature 2)
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  String _selectedFilter = 'Semua';

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: Color(0xFF135A4B)),
            SizedBox(width: 10),
            Text('Izin Notifikasi', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'ServisKu memerlukan izin notifikasi untuk mengingatkan Anda saat kilometer motor mendekati batas penggantian oli, busi, dan servis berkala lainnya.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationPermissionProvider.notifier).setStatus(
                  NotificationPermissionStatus.denied);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Izin notifikasi ditolak. Anda tidak akan menerima peringatan otomatis.'),
                ),
              );
            },
            child: const Text('Tolak / Nanti', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135A4B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(notificationPermissionProvider.notifier).setStatus(
                  NotificationPermissionStatus.granted);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF135A4B),
                  content: Text('Izin notifikasi aktif! Anda akan menerima pengingat servis.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              );
            },
            child: const Text('Izinkan Notifikasi'),
          ),
        ],
      ),
    );
  }

  void _triggerSimulatedReminder() {
    final newNotif = ServiceNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: '🚨 Peringatan: Ganti Oli Mesin Segera!',
      message: 'Odometer motor Anda mencapai 10.000 km. Batas interval 2.000 km telah jatuh tempo.',
      timestamp: DateTime.now(),
      isRead: false,
      type: 'warning',
      componentName: 'Oli Mesin',
      isUrgent: true,
    );

    ref.read(notificationProvider.notifier).addNotification(newNotif);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pengingat Baru: ${newNotif.title}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF7F9F9);
    const accentColor = Color(0xFF135A4B);

    final notifState = ref.watch(notificationProvider);
    final permission = ref.watch(notificationPermissionProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifikasi & Pengingat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Simulasi Trigger Pengingat',
            icon: const Icon(Icons.notification_add_outlined, color: Colors.white),
            onPressed: _triggerSimulatedReminder,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'read_all') {
                ref.read(notificationProvider.notifier).markAllAsRead();
              } else if (val == 'clear_all') {
                ref.read(notificationProvider.notifier).clearAll();
              } else if (val == 'permission') {
                _showPermissionDialog();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: Color(0xFF135A4B), size: 18),
                    SizedBox(width: 8),
                    Text('Tandai Semua Dibaca', style: TextStyle(color: Color(0xFF1E293B))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Hapus Semua Notifikasi', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'permission',
                child: Row(
                  children: [
                    Icon(Icons.security, color: Color(0xFF64748B), size: 18),
                    SizedBox(width: 8),
                    Text('Kelola Izin Notifikasi', style: TextStyle(color: Color(0xFF1E293B))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Status Izin Notifikasi (Permission State handling)
          if (permission != NotificationPermissionStatus.granted)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_off_outlined, color: Colors.amber),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Izin Notifikasi Nonaktif',
                          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Aktifkan agar pengingat servis berkala muncul tepat waktu.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showPermissionDialog,
                    child: const Text('Aktifkan', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Filter Segment: Semua, Pengingat, Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('Pengingat'),
                const SizedBox(width: 8),
                _buildFilterChip('Penting'),
              ],
            ),
          ),

          // List Notifikasi (Loading, Empty, Loaded)
          Expanded(
            child: notifState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 8),
                    Text('Gagal memuat notifikasi: $err', style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
              data: (list) {
                // Terapkan filter
                var filtered = list;
                if (_selectedFilter == 'Pengingat') {
                  filtered = list.where((n) => n.type == 'reminder' || n.type == 'warning').toList();
                } else if (_selectedFilter == 'Penting') {
                  filtered = list.where((n) => n.isUrgent).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_none_rounded, size: 64, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum Ada Notifikasi',
                          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Peringatan jadwal servis kendaraan akan muncul di sini.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final item = filtered[index];
                    return _buildNotificationCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
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

  Widget _buildNotificationCard(ServiceNotification item) {
    final iconData = item.isUrgent
        ? Icons.warning_rounded
        : (item.type == 'success' ? Icons.check_circle_rounded : Icons.info_outline_rounded);
    final iconColor = item.isUrgent
        ? const Color(0xFFEF4444)
        : (item.type == 'success' ? const Color(0xFF135A4B) : const Color(0xFF2563EB));

    return InkWell(
      onTap: () {
        ref.read(notificationProvider.notifier).markAsRead(item.id);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isUrgent
                ? Colors.red.shade300
                : (item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFF135A4B).withValues(alpha: 0.5)),
            width: item.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: const Color(0xFF1E293B),
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF135A4B),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(item.timestamp),
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
