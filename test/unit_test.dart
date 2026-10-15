import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serviceku/models/service_component.dart';
import 'package:serviceku/models/service_history.dart';
import 'package:serviceku/models/vehicle_info.dart';
import 'package:serviceku/providers/service_provider.dart';
import 'package:serviceku/repositories/service_repository.dart';

// Mock Repository
class MockServiceRepository extends ServiceRepository {
  List<ServiceHistory> db = [];
  bool fetchCalled = false;

  @override
  Future<List<ServiceHistory>> fetchServiceHistory() async {
    fetchCalled = true;
    return List<ServiceHistory>.from(db);
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

  VehicleInfo mockVehicle = VehicleInfo.defaultVehicle;

  @override
  Future<VehicleInfo> fetchVehicleInfo() async => mockVehicle;

  @override
  Future<void> saveVehicleInfo(VehicleInfo info) async => mockVehicle = info;

  List<ServiceComponent> mockComponents = List<ServiceComponent>.from(ServiceComponent.defaultPresets);

  @override
  Future<List<ServiceComponent>> fetchComponents() async => List<ServiceComponent>.from(mockComponents);

  @override
  Future<void> addComponent(ServiceComponent component) async {
    mockComponents.removeWhere((e) => e.id == component.id);
    mockComponents.add(component);
  }

  @override
  Future<void> updateComponent(ServiceComponent component) async {
    final index = mockComponents.indexWhere((e) => e.id == component.id);
    if (index != -1) mockComponents[index] = component;
  }

  @override
  Future<void> deleteComponent(String id) async {
    mockComponents.removeWhere((e) => e.id == id);
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

  group('ServiceComponentsNotifier Unit Tests', () {
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

    test('Initial state loads default presets', () async {
      final list = await container.read(serviceComponentsProvider.future);
      expect(list.isNotEmpty, isTrue);
      expect(list.any((c) => c.nama == 'Oli Mesin'), isTrue);
    });

    test('addComponent adds custom component', () async {
      await container.read(serviceComponentsProvider.future);
      const customComp = ServiceComponent(
        id: 'c-test-1',
        nama: 'Rantai & Gear SSS',
        intervalKm: 15000,
        deskripsi: 'Pelumas berkala',
        isCustom: true,
      );

      await container.read(serviceComponentsProvider.notifier).addComponent(customComp);
      final state = container.read(serviceComponentsProvider).value;
      expect(state!.any((c) => c.id == 'c-test-1'), isTrue);
      expect(state.firstWhere((c) => c.id == 'c-test-1').nama, 'Rantai & Gear SSS');
    });

    test('updateComponent modifies existing component', () async {
      await container.read(serviceComponentsProvider.future);
      const updated = ServiceComponent(
        id: 'comp_oli_mesin',
        nama: 'Oli Mesin Full Sintetik',
        intervalKm: 3000,
      );

      await container.read(serviceComponentsProvider.notifier).updateComponent(updated);
      final state = container.read(serviceComponentsProvider).value;
      final found = state!.firstWhere((c) => c.id == 'comp_oli_mesin');
      expect(found.nama, 'Oli Mesin Full Sintetik');
      expect(found.intervalKm, 3000);
    });

    test('deleteComponent removes component', () async {
      await container.read(serviceComponentsProvider.future);
      await container.read(serviceComponentsProvider.notifier).deleteComponent('comp_busi');
      final state = container.read(serviceComponentsProvider).value;
      expect(state!.any((c) => c.id == 'comp_busi'), isFalse);
    });
  });
}
