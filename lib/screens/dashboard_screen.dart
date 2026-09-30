import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_provider.dart';
import 'form_service_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceState = ref.watch(serviceHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Servis Kendaraan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(serviceHistoryProvider.notifier).refreshData();
            },
          )
        ],
      ),
      body: serviceState.when(
        // Kondisi 1: Initial loading di DashboardScreen
        loading: () => const Center(child: CircularProgressIndicator()),
        
        // Kondisi 4: Error state dengan tombol Retry untuk memuat ulang data
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
        
        // Kondisi 2 & 3: Data berhasil dimuat atau Empty State
        data: (data) {
          // Kondisi 3: Empty state jika data kosong
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat servis.\nSilakan tambah data baru.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Kondisi 2: Data berhasil dimuat (tampilkan dalam ListView)
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final service = data[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    service.jenisServis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Odometer: ${service.odometer} km'),
                      Text('Biaya: Rp${service.totalBiaya}'),
                      const SizedBox(height: 4),
                      Text(
                        'Tanggal: ${service.date.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      service.status,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: service.status == 'Selesai' 
                        ? Colors.green.shade100 
                        : Colors.orange.shade100,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormServisScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
