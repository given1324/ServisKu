import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serviceku/models/service_history.dart';
import 'package:serviceku/providers/service_provider.dart';
import 'package:serviceku/repositories/service_repository.dart';

// Mock Repository
class MockServiceRepository extends ServiceRepository {
  List<ServiceHistory> db = [];
  bool fetchCalled = false;

  @override
  Future<List<ServiceHistory>> fetchServiceHistory() async {
    fetchCalled = true;
    return db;
  }

  @override
  Future<void> addServiceHistory(ServiceHistory service) async {
    db.add(service);
  }

  @override
  Future<void> updateServiceHistory(ServiceHistory service) async {
    final index = db.indexWhere((e) => e.id == service.id);
    if (index != -1) {
      db[index] = service;
    }
  }

  @override
  Future<void> deleteServiceHistory(String id) async {
    db.removeWhere((e) => e.id == id);
  }
}

void main() {
  group('ServiceHistoryNotifier Unit Tests', () {
    late ProviderContainer container;
    late MockServiceRepository mockRepo;

    setUp(() {
      mockRepo = MockServiceRepository();
      container = ProviderContainer(
        overrides: [
          serviceRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is loading then empty list', () async {
      // Membaca provider akan memicu build() yang memanggil fetchServiceHistory
      final asyncValue = container.read(serviceHistoryProvider);
      
      // Karena asinkron, state awal mungkin loading
      expect(asyncValue.isLoading, true);

      // Tunggu hingga proses selesai
      final finalValue = await container.read(serviceHistoryProvider.future);
      expect(finalValue, isEmpty);
      expect(mockRepo.fetchCalled, true);
    });

    test('addService updates local state optimistically', () async {
      // Tunggu inisialisasi awal
      await container.read(serviceHistoryProvider.future);

      final newService = ServiceHistory(
        id: '1',
        jenisServis: 'Ganti Ban',
        odometer: 10000,
        totalBiaya: 250000,
        createdAt: DateTime.now(),
        status: 'Selesai',
      );

      // Panggil method add
      await container.read(serviceHistoryProvider.notifier).addService(newService);

      // Verifikasi state lokal terupdate
      final state = container.read(serviceHistoryProvider).value;
      expect(state, isNotNull);
      expect(state!.length, 1);
      expect(state.first.jenisServis, 'Ganti Ban');
      
      // Verifikasi data masuk ke "database"
      expect(mockRepo.db.length, 1);
    });

    test('updateService updates existing item in state', () async {
      // Setup data awal
      final initialService = ServiceHistory(
        id: '1',
        jenisServis: 'Ganti Oli',
        odometer: 5000,
        totalBiaya: 50000,
        createdAt: DateTime.now(),
        status: 'Belum Selesai',
      );
      mockRepo.db = [initialService];

      await container.read(serviceHistoryProvider.future);

      // Modifikasi data
      final updatedService = initialService.copyWith(
        jenisServis: 'Ganti Oli Premium',
        status: 'Selesai',
      );

      // Panggil update
      await container.read(serviceHistoryProvider.notifier).updateService(updatedService);

      // Verifikasi
      final state = container.read(serviceHistoryProvider).value;
      expect(state!.length, 1);
      expect(state.first.jenisServis, 'Ganti Oli Premium');
      expect(state.first.status, 'Selesai');
    });

    test('deleteService removes item from state', () async {
      final service = ServiceHistory(
        id: '1',
        jenisServis: 'Servis Ringan',
        odometer: 5000,
        totalBiaya: 100000,
        createdAt: DateTime.now(),
        status: 'Selesai',
      );
      mockRepo.db = [service];

      await container.read(serviceHistoryProvider.future);
      expect(container.read(serviceHistoryProvider).value!.length, 1);

      // Hapus data
      await container.read(serviceHistoryProvider.notifier).deleteService('1');

      // Verifikasi
      final state = container.read(serviceHistoryProvider).value;
      expect(state, isEmpty);
      expect(mockRepo.db, isEmpty);
    });
  });
}
