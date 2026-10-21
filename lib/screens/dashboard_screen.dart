import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_component.dart';
import '../models/service_history.dart';
import '../models/vehicle_info.dart';
import '../providers/service_provider.dart';
import '../services/api_service.dart';
import 'components_screen.dart';
import 'form_motor_screen.dart';
import 'form_service_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _topCardIndex = 0;

  IconData _getComponentIcon(String nama) {
    final l = nama.toLowerCase();
    if (l.contains('oli')) return Icons.speed_outlined;
    if (l.contains('rem')) return Icons.disc_full_outlined;
    if (l.contains('busi')) return Icons.bolt_outlined;
    if (l.contains('filter')) return Icons.air_outlined;
    if (l.contains('cvt') || l.contains('v-belt')) return Icons.all_inclusive;
    if (l.contains('coolant') || l.contains('radiator')) return Icons.water_drop_outlined;
    if (l.contains('rantai') || l.contains('gir') || l.contains('gear')) return Icons.link_rounded;
    if (l.contains('ban')) return Icons.radio_button_checked;
    if (l.contains('aki') || l.contains('baterai')) return Icons.battery_charging_full_rounded;
    return Icons.build_circle_outlined;
  }

  Color _getComponentColor(String nama) {
    final l = nama.toLowerCase();
    if (l.contains('oli')) return const Color(0xFFD68A36);
    if (l.contains('rem')) return const Color(0xFF4B87AD);
    if (l.contains('busi')) return const Color(0xFF8E44AD);
    if (l.contains('filter')) return const Color(0xFF16A085);
    if (l.contains('cvt') || l.contains('v-belt')) return const Color(0xFFE67E22);
    if (l.contains('coolant') || l.contains('radiator')) return const Color(0xFF2980B9);
    if (l.contains('rantai') || l.contains('gir')) return const Color(0xFF27AE60);
    if (l.contains('aki')) return const Color(0xFFC0392B);
    return const Color(0xFF2E8C78);
  }

  Color _getComponentBgColor(String nama) {
    final l = nama.toLowerCase();
    if (l.contains('oli')) return const Color(0xFFFDF0E1);
    if (l.contains('rem')) return const Color(0xFFE8F2F9);
    if (l.contains('busi')) return const Color(0xFFF4ECF7);
    if (l.contains('filter')) return const Color(0xFFE8F8F5);
    if (l.contains('cvt') || l.contains('v-belt')) return const Color(0xFFFBEEE6);
    if (l.contains('coolant') || l.contains('radiator')) return const Color(0xFFEBF5FB);
    if (l.contains('rantai') || l.contains('gir')) return const Color(0xFFEAFAF1);
    if (l.contains('aki')) return const Color(0xFFFDEDEC);
    return const Color(0xFFE4F2EF);
  }

  Widget _buildComponentCard({
    required ServiceComponent comp,
    required List<ServiceHistory> historyList,
    required int currentOdo,
    double? width,
  }) {
    final relatedServices = historyList.where(
      (s) => s.jenisServis.toLowerCase().contains(comp.nama.toLowerCase()),
    ).toList();

    final int lastServicedKm = relatedServices.isNotEmpty
        ? relatedServices.first.odometer
        : 0;

    final int nextServiceKm = lastServicedKm > 0
        ? (lastServicedKm + comp.intervalKm)
        : (currentOdo > 0 ? (currentOdo + comp.intervalKm) : comp.intervalKm);

    final int kmRemaining = nextServiceKm > currentOdo
        ? (nextServiceKm - currentOdo)
        : 0;

    final bool isOverdue = currentOdo >= nextServiceKm && currentOdo > 0;
    final bool isWarning = kmRemaining > 0 && kmRemaining <= 500;

    final double progress = lastServicedKm > 0
        ? ((comp.intervalKm - kmRemaining) / comp.intervalKm).clamp(0.0, 1.0)
        : (currentOdo > 0 ? (currentOdo / nextServiceKm).clamp(0.0, 1.0) : 0.0);

    final Color statusColor = isOverdue
        ? Colors.red
        : (isWarning ? Colors.orange : const Color(0xFFD68A36));

    final IconData iconData = _getComponentIcon(comp.nama);
    final Color iconColor = _getComponentColor(comp.nama);
    final Color iconBg = _getComponentBgColor(comp.nama);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: FormServisScreen(
              existingService: null,
              initialJenisServis: comp.nama,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOverdue ? Colors.red.shade200 : Colors.grey.shade100,
            width: isOverdue ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(iconData, color: iconColor, size: 20),
                    ),
                    if (comp.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF135A4B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Kustom', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF135A4B))),
                      )
                    else if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Servis!', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    comp.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: iconColor),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${NumberFormat.decimalPattern().format(nextServiceKm)} km',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(+${NumberFormat.decimalPattern().format(comp.intervalKm)})',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOverdue
                      ? 'Waktunya ganti/servis!'
                      : (kmRemaining > 0
                          ? 'Sekitar ${NumberFormat.decimalPattern().format(kmRemaining)} km lagi'
                          : 'Kondisi baik'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isOverdue ? Colors.red : (isWarning ? Colors.orange : Colors.grey.shade600),
                    fontSize: 10,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRightCard({
    required List<ServiceComponent> displayComponents,
    required List<ServiceHistory> historyList,
    required int currentOdo,
  }) {
    if (displayComponents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('Belum ada komponen')),
      );
    }

    final safeIndex = _topCardIndex.clamp(0, displayComponents.length - 1);
    final comp = displayComponents[safeIndex];

    final relatedServices = historyList.where(
      (s) => s.jenisServis.toLowerCase().contains(comp.nama.toLowerCase()),
    ).toList();

    final int lastServicedKm = relatedServices.isNotEmpty
        ? relatedServices.first.odometer
        : 0;

    final int nextServiceKm = lastServicedKm > 0
        ? (lastServicedKm + comp.intervalKm)
        : (currentOdo > 0 ? (currentOdo + comp.intervalKm) : comp.intervalKm);

    final int kmRemaining = nextServiceKm > currentOdo
        ? (nextServiceKm - currentOdo)
        : 0;

    final bool isOverdue = currentOdo >= nextServiceKm && currentOdo > 0;
    final bool isWarning = kmRemaining > 0 && kmRemaining <= 500;

    final double progress = lastServicedKm > 0
        ? ((comp.intervalKm - kmRemaining) / comp.intervalKm).clamp(0.0, 1.0)
        : (currentOdo > 0 ? (currentOdo / nextServiceKm).clamp(0.0, 1.0) : 0.0);

    final Color statusColor = isOverdue
        ? Colors.red
        : (isWarning ? Colors.orange : const Color(0xFFD68A36));

    final IconData iconData = _getComponentIcon(comp.nama);
    final Color iconColor = _getComponentColor(comp.nama);
    final Color iconBg = _getComponentBgColor(comp.nama);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: FormServisScreen(
              existingService: null,
              initialJenisServis: comp.nama,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOverdue ? Colors.red.shade200 : Colors.transparent,
            width: isOverdue ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                if (displayComponents.length > 1)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _topCardIndex = (_topCardIndex - 1 + displayComponents.length) % displayComponents.length;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(3.0),
                          child: Icon(Icons.chevron_left, size: 18, color: Colors.grey),
                        ),
                      ),
                      Text(
                        '${safeIndex + 1}/${displayComponents.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _topCardIndex = (_topCardIndex + 1) % displayComponents.length;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(3.0),
                          child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: iconBg, 
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Jadwal ${comp.nama.toLowerCase()}', 
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: iconColor),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${NumberFormat.decimalPattern().format(nextServiceKm)} km',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(+${NumberFormat.decimalPattern().format(comp.intervalKm)})',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress, 
                backgroundColor: const Color(0xFFEEEEEE), 
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isOverdue
                  ? 'Waktunya servis!'
                  : (kmRemaining > 0
                      ? 'Sekitar ${NumberFormat.decimalPattern().format(kmRemaining)} km lagi'
                      : 'Kondisi baik'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isOverdue ? Colors.red : (isWarning ? Colors.orange : Colors.grey),
                fontSize: 10,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(serviceHistoryProvider);
    final vehicleState = ref.watch(vehicleInfoProvider);
    final componentsState = ref.watch(serviceComponentsProvider);
    final vehicle = vehicleState.value ?? VehicleInfo.defaultVehicle;
    final components = componentsState.value ?? [];
    
    // Helper to format currency
    final currencyFormatter = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F9),
      body: SafeArea(
        child: serviceState.when(
          // Kondisi 1: Initial loading di DashboardScreen
          loading: () => const Center(child: CircularProgressIndicator()),
          
          // Kondisi 4: Error state dengan tombol Retry
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red.shade400),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan saat memuat data.\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135A4B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      SimulatedBackendClient.simulateError = false;
                      ref.read(serviceHistoryProvider.notifier).refreshData();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
          
          // Data berhasil dimuat
          data: (data) {
            int totalPengeluaran = data.fold(0, (sum, item) => sum + item.totalBiaya);
            int totalServis = data.length;
            int lastOdometer = data.isEmpty ? 0 : data.map((e) => e.odometer).reduce((a, b) => a > b ? a : b);

            // Daftar komponen terurut (Oli, kemudian Komponen Kustom yang baru ditambah, kemudian preset lainnya)
            final displayComponents = [
              ...components.where((c) => c.nama.toLowerCase().contains('oli')),
              ...components.where((c) => c.isCustom && !c.nama.toLowerCase().contains('oli')),
              ...components.where((c) => !c.isCustom && !c.nama.toLowerCase().contains('oli')),
            ];
            
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
                                    color: Colors.white.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          InkWell(
                                            onTap: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.transparent,
                                                builder: (context) => Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: MediaQuery.of(context).viewInsets.bottom,
                                                  ),
                                                  child: FormMotorScreen(currentVehicle: vehicle),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.edit, size: 12, color: Colors.white),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        vehicle.namaMotor,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (vehicle.platNomor.isNotEmpty || vehicle.tahun > 0) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${vehicle.platNomor} • Th ${vehicle.tahun}',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
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
                                child: _buildTopRightCard(
                                  displayComponents: displayComponents,
                                  historyList: data,
                                  currentOdo: lastOdometer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Section: Pantauan Komponen (Mirip kartu ganti oli)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pantauan Komponen',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Target jadwal & estimasi servis berkala',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ComponentsScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF135A4B),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: Text(
                                  'Kelola (${components.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                label: const Icon(Icons.arrow_forward_ios, size: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 195,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: displayComponents.length + 1,
                              separatorBuilder: (context, index) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                if (index < displayComponents.length) {
                                  final comp = displayComponents[index];
                                  return _buildComponentCard(
                                    comp: comp,
                                    historyList: data,
                                    currentOdo: lastOdometer,
                                    width: 180,
                                  );
                                }
                                // Card Tambah Komponen
                                return InkWell(
                                  onTap: () => showAddComponentDialog(context, ref),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 150,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF135A4B).withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF135A4B).withValues(alpha: 0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_circle_outline,
                                            color: Color(0xFF135A4B),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Tambah\nKomponen',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF135A4B),
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Custom interval',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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
                                    trailing: PopupMenuButton<String>(
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
                                    ),
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
