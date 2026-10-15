import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/service_component.dart';
import '../models/service_history.dart';
import '../providers/service_provider.dart';
import 'form_service_screen.dart';

class ComponentsScreen extends ConsumerStatefulWidget {
  const ComponentsScreen({super.key});

  @override
  ConsumerState<ComponentsScreen> createState() => _ComponentsScreenState();
}

Future<void> showAddComponentDialog(
  BuildContext context,
  WidgetRef ref, {
  ServiceComponent? existing,
}) async {
  final formKey = GlobalKey<FormState>();
  final namaController = TextEditingController(text: existing?.nama ?? '');
  final intervalController = TextEditingController(
    text: existing != null ? existing.intervalKm.toString() : '',
  );
  final deskripsiController = TextEditingController(text: existing?.deskripsi ?? '');

  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF135A4B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build, color: Color(0xFF135A4B), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            existing == null ? 'Tambah Komponen' : 'Edit Komponen',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nama Komponen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              TextFormField(
                controller: namaController,
                decoration: InputDecoration(
                  hintText: 'Misal: Rantai & Gir, Minyak Rem',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 14),

              const Text('Interval Servis (km)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              TextFormField(
                controller: intervalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Misal: 10000',
                  suffixText: 'km',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Interval wajib diisi';
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Masukkan angka km yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              const Text('Catatan / Keterangan (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              TextFormField(
                controller: deskripsiController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Keterangan waktu penggantian atau merk',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF135A4B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;

            final component = ServiceComponent(
              id: existing?.id ?? 'comp_${DateTime.now().millisecondsSinceEpoch}',
              nama: namaController.text.trim(),
              intervalKm: int.parse(intervalController.text.trim()),
              deskripsi: deskripsiController.text.trim(),
              isCustom: true,
            );

            if (existing == null) {
              await ref.read(serviceComponentsProvider.notifier).addComponent(component);
            } else {
              await ref.read(serviceComponentsProvider.notifier).updateComponent(component);
            }

            if (ctx.mounted) {
              Navigator.pop(ctx);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(existing == null ? 'Komponen berhasil ditambahkan!' : 'Komponen berhasil diperbarui!'),
                  backgroundColor: const Color(0xFF135A4B),
                ),
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

class _ComponentsScreenState extends ConsumerState<ComponentsScreen> {
  void _showAddComponentDialog({ServiceComponent? existing}) {
    showAddComponentDialog(context, ref, existing: existing);
  }

  @override
  Widget build(BuildContext context) {
    final componentsState = ref.watch(serviceComponentsProvider);
    final serviceHistoryState = ref.watch(serviceHistoryProvider);

    final List<ServiceHistory> historyList = serviceHistoryState.value ?? [];
    final int currentOdo = historyList.isEmpty
        ? 0
        : historyList.map((e) => e.odometer).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F9),
      appBar: AppBar(
        title: const Text('Komponen & Jadwal Servis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF135A4B),
        elevation: 0.5,
      ),
      body: componentsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat komponen: $err')),
        data: (components) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF135A4B), Color(0xFF1C7A65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.checklist_rtl_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jadwal Perawatan Berkala',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Odometer saat ini: ${NumberFormat.decimalPattern().format(currentOdo)} km. Pantau jadwal ganti komponen agar performa motor selalu prima.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sub-header + Button Tambah Komponen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Komponen (${components.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF333333)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddComponentDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Komponen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135A4B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List of components
              ...components.map((comp) {
                // Cari servis terakhir untuk komponen ini
                final relatedServices = historyList.where(
                  (s) => s.jenisServis.toLowerCase().contains(comp.nama.toLowerCase()),
                ).toList();

                final int lastServicedKm = relatedServices.isNotEmpty
                    ? relatedServices.first.odometer
                    : 0;

                final int nextServiceKm = lastServicedKm > 0
                    ? (lastServicedKm + comp.intervalKm)
                    : comp.intervalKm;

                final int kmRemaining = nextServiceKm > currentOdo
                    ? (nextServiceKm - currentOdo)
                    : 0;

                final bool isOverdue = currentOdo >= nextServiceKm && currentOdo > 0;
                final bool isWarning = kmRemaining > 0 && kmRemaining <= 500;

                final Color statusColor = isOverdue
                    ? Colors.red
                    : (isWarning ? Colors.orange : const Color(0xFF135A4B));

                final String statusLabel = isOverdue
                    ? 'Waktunya Servis!'
                    : (isWarning ? 'Segera Servis' : 'Kondisi Baik');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isOverdue ? Colors.red.shade200 : Colors.grey.shade200,
                      width: isOverdue ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.settings_outlined, color: statusColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comp.nama,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        'Interval: setiap ${NumberFormat.decimalPattern().format(comp.intervalKm)} km',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (comp.deskripsi.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          comp.deskripsi,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lastServicedKm > 0
                                ? 'Terakhir di ${NumberFormat.decimalPattern().format(lastServicedKm)} km • Sisa $kmRemaining km'
                                : 'Belum pernah dicatat di riwayat',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                          Row(
                            children: [
                              if (comp.isCustom) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                                  onPressed: () => _showAddComponentDialog(existing: comp),
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Hapus Komponen'),
                                        content: Text('Hapus komponen "${comp.nama}"?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(serviceComponentsProvider.notifier).deleteComponent(comp.id);
                                    }
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('Catat Servis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF135A4B),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                      child: FormServisScreen(
                                        existingService: null,
                                        initialJenisServis: comp.nama,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
