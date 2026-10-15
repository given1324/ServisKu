import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serviceku/models/service_component.dart';
import 'package:serviceku/models/service_history.dart';
import 'package:serviceku/models/vehicle_info.dart';
import 'package:serviceku/providers/service_provider.dart';
import 'package:serviceku/repositories/service_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Data Model & Serialization Tests', () {
    test('ServiceHistory toMap and fromMap preserves all fields', () {
      final now = DateTime.now();
      final original = ServiceHistory(
        id: 'srv-001',
        jenisServis: 'Ganti Oli & Filter Mesin',
        odometer: 15400,
        totalBiaya: 175000,
        createdAt: now,
        completedAt: now.add(const Duration(hours: 1)),
        status: 'Selesai',
        catatan: 'Menggunakan oli sintetis 10W-40',
      );

      final map = original.toMap();
      final restored = ServiceHistory.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.jenisServis, original.jenisServis);
      expect(restored.odometer, original.odometer);
      expect(restored.totalBiaya, original.totalBiaya);
      expect(restored.createdAt.millisecondsSinceEpoch, original.createdAt.millisecondsSinceEpoch);
      expect(restored.completedAt?.millisecondsSinceEpoch, original.completedAt?.millisecondsSinceEpoch);
      expect(restored.status, original.status);
      expect(restored.catatan, original.catatan);
    });

    test('ServiceHistory toJson and fromJson serialization works', () {
      final original = ServiceHistory(
        id: 'srv-002',
        jenisServis: 'Tune Up Karburator',
        odometer: 20000,
        totalBiaya: 120000,
        createdAt: DateTime(2026, 10, 15, 14, 30),
        status: 'Belum Selesai',
      );

      final jsonString = original.toJson();
      expect(jsonString, isA<String>());
      expect(jsonString.contains('srv-002'), isTrue);

      final fromJsonObj = ServiceHistory.fromJson(jsonString);
      expect(fromJsonObj.id, 'srv-002');
      expect(fromJsonObj.jenisServis, 'Tune Up Karburator');
      expect(fromJsonObj.status, 'Belum Selesai');
      expect(fromJsonObj.catatan, isNull);
    });

    test('ServiceComponent toMap and fromMap preserves all fields', () {
      const original = ServiceComponent(
        id: 'comp_custom_1',
        nama: 'Minyak Rem DOT 4',
        intervalKm: 20000,
        deskripsi: 'Ganti kuras cairan minyak rem',
        isCustom: true,
      );

      final map = original.toMap();
      final restored = ServiceComponent.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.nama, original.nama);
      expect(restored.intervalKm, original.intervalKm);
      expect(restored.deskripsi, original.deskripsi);
      expect(restored.isCustom, isTrue);
    });

    test('ServiceComponent toJson and fromJson serialization works', () {
      const original = ServiceComponent(
        id: 'comp_custom_2',
        nama: 'Kampas Kopling',
        intervalKm: 30000,
        deskripsi: 'Cek ketebalan kampas kopling',
        isCustom: true,
      );

      final jsonStr = original.toJson();
      final fromJsonObj = ServiceComponent.fromJson(jsonStr);

      expect(fromJsonObj.id, 'comp_custom_2');
      expect(fromJsonObj.nama, 'Kampas Kopling');
      expect(fromJsonObj.intervalKm, 30000);
      expect(fromJsonObj.isCustom, isTrue);
    });
  });

  group('2. Local Storage & Persistence CRUD Tests (Simulasi Restart Aplikasi)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('CREATE: Data disimpan ke SharedPreferences dan dapat dibaca (READ)', () async {
      final repo = ServiceRepository(prefs: prefs);

      final newService = ServiceHistory(
        id: 'srv-101',
        jenisServis: 'Ganti Ban Belakang Tubeless',
        odometer: 12500,
        totalBiaya: 320000,
        createdAt: DateTime.now(),
        status: 'Selesai',
        catatan: 'Ban Maxxis Diamond 90/90-14',
      );

      // Create
      await repo.addServiceHistory(newService);

      // Verifikasi data mentah ada di local storage SharedPreferences
      final rawData = prefs.getString(ServiceRepository.storageKey);
      expect(rawData, isNotNull);
      expect(rawData!.contains('Ganti Ban Belakang Tubeless'), isTrue);

      // Read
      final items = await repo.fetchServiceHistory();
      expect(items.length, 1);
      expect(items.first.id, 'srv-101');
      expect(items.first.jenisServis, 'Ganti Ban Belakang Tubeless');
    });

    test('PERSISTENCE TEST: Data tetap ada saat aplikasi ditutup dan dibuka kembali (cold restart)', () async {
      // Sesi 1: Aplikasi berjalan dan menyimpan 2 catatan servis
      final session1Repo = ServiceRepository(prefs: prefs);
      await session1Repo.addServiceHistory(ServiceHistory(
        id: 'persist-1',
        jenisServis: 'Servis Rutin Berkala',
        odometer: 5000,
        totalBiaya: 150000,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        status: 'Selesai',
      ));
      await session1Repo.addServiceHistory(ServiceHistory(
        id: 'persist-2',
        jenisServis: 'Ganti Kampas Rem Depan',
        odometer: 5100,
        totalBiaya: 65000,
        createdAt: DateTime.now(),
        status: 'Belum Selesai',
      ));

      // Simulasi: Aplikasi ditutup (instance lama di-destroy / garbage collected)
      // Sesi 2: Aplikasi baru dibuka kembali (instansiasi repository baru dari storage yang sama)
      final session2Repo = ServiceRepository(prefs: prefs);
      final restoredList = await session2Repo.fetchServiceHistory();

      expect(restoredList.length, 2);
      expect(restoredList.any((e) => e.id == 'persist-1'), isTrue);
      expect(restoredList.any((e) => e.id == 'persist-2'), isTrue);
    });

    test('UPDATE: Perubahan data bertahan saat aplikasi di-restart', () async {
      final repoSession1 = ServiceRepository(prefs: prefs);
      final initialService = ServiceHistory(
        id: 'edit-1',
        jenisServis: 'Ganti Aki',
        odometer: 18000,
        totalBiaya: 250000,
        createdAt: DateTime.now(),
        status: 'Belum Selesai',
      );
      await repoSession1.addServiceHistory(initialService);

      // Lakukan Update (misal: pekerjaan servis selesai)
      final completedService = initialService.copyWith(
        status: 'Selesai',
        completedAt: DateTime.now(),
        catatan: 'Garansi aki 6 bulan',
      );
      await repoSession1.updateServiceHistory(completedService);

      // Simulasi buka kembali aplikasi dengan instance repository baru
      final repoSession2 = ServiceRepository(prefs: prefs);
      final list = await repoSession2.fetchServiceHistory();

      expect(list.length, 1);
      expect(list.first.status, 'Selesai');
      expect(list.first.catatan, 'Garansi aki 6 bulan');
      expect(list.first.completedAt, isNotNull);
    });

    test('DELETE: Penghapusan data bertahan saat aplikasi di-restart', () async {
      final repoSession1 = ServiceRepository(prefs: prefs);
      await repoSession1.addServiceHistory(ServiceHistory(
        id: 'del-1',
        jenisServis: 'Item 1',
        odometer: 1000,
        totalBiaya: 10000,
        createdAt: DateTime.now(),
        status: 'Selesai',
      ));
      await repoSession1.addServiceHistory(ServiceHistory(
        id: 'del-2',
        jenisServis: 'Item 2',
        odometer: 2000,
        totalBiaya: 20000,
        createdAt: DateTime.now(),
        status: 'Selesai',
      ));

      // Hapus Item 1
      await repoSession1.deleteServiceHistory('del-1');

      // Simulasi restart aplikasi
      final repoSession2 = ServiceRepository(prefs: prefs);
      final list = await repoSession2.fetchServiceHistory();

      expect(list.length, 1);
      expect(list.first.id, 'del-2');
      expect(list.any((e) => e.id == 'del-1'), isFalse);
    });
  });

  group('3. Full Vertical Flow Tests (Riverpod Notifier => SharedPreferences)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Alur Vertikal Lengkap: UI Notifier memanipulasi data dan tersimpan permanen di Local Storage', () async {
      // Sesi 1: State management Riverpod terhubung dengan repository dan SharedPreferences
      final container1 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      // Tunggu state awal siap
      await container1.read(serviceHistoryProvider.future);

      final item = ServiceHistory(
        id: 'flow-01',
        jenisServis: 'Ganti V-Belt & Roller CVT',
        odometer: 24000,
        totalBiaya: 210000,
        createdAt: DateTime.now(),
        status: 'Selesai',
        catatan: 'Original Honda Genuine Parts',
      );

      // FE memanggil notifier addService
      await container1.read(serviceHistoryProvider.notifier).addService(item);

      // Verifikasi state lokal Riverpod di sesi 1
      final state1 = container1.read(serviceHistoryProvider).value;
      expect(state1!.length, 1);
      expect(state1.first.jenisServis, 'Ganti V-Belt & Roller CVT');

      // Dispose container 1 (simulasi aplikasi ditutup)
      container1.dispose();

      // Sesi 2: Booting aplikasi kembali (cold start dengan ProviderContainer baru)
      final container2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final state2 = await container2.read(serviceHistoryProvider.future);
      expect(state2.length, 1);
      expect(state2.first.id, 'flow-01');
      expect(state2.first.jenisServis, 'Ganti V-Belt & Roller CVT');
      expect(state2.first.catatan, 'Original Honda Genuine Parts');

      container2.dispose();
    });

    test('PERSISTENCE TEST: Perubahan informasi motor (VehicleInfo) tetap tersimpan saat cold restart aplikasi', () async {
      // Sesi 1: Update info motor
      final container1 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await container1.read(vehicleInfoProvider.future);
      const newMotor = VehicleInfo(
        namaMotor: 'Yamaha Aerox 155 Connected',
        platNomor: 'D 5678 KLM',
        tahun: 2024,
      );

      await container1.read(vehicleInfoProvider.notifier).updateVehicleInfo(newMotor);
      container1.dispose();

      // Sesi 2: Aplikasi dibuka kembali dari awal
      final container2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final restoredMotor = await container2.read(vehicleInfoProvider.future);
      expect(restoredMotor.namaMotor, 'Yamaha Aerox 155 Connected');
      expect(restoredMotor.platNomor, 'D 5678 KLM');
      expect(restoredMotor.tahun, 2024);

      container2.dispose();
    });

    test('PERSISTENCE TEST: Penambahan & modifikasi komponen servis kustom bertahan saat cold restart', () async {
      // Sesi 1: Tambah komponen kustom baru
      final container1 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await container1.read(serviceComponentsProvider.future);
      const customComponent = ServiceComponent(
        id: 'comp_custom_rantai',
        nama: 'Rantai & Gir Paket SSS',
        intervalKm: 18000,
        deskripsi: 'Pelumasan tiap minggu, ganti gir paket berkala',
        isCustom: true,
      );

      await container1.read(serviceComponentsProvider.notifier).addComponent(customComponent);
      
      // Verifikasi komponen ada di sesi 1
      final state1 = container1.read(serviceComponentsProvider).value;
      expect(state1!.any((c) => c.id == 'comp_custom_rantai'), isTrue);
      container1.dispose();

      // Sesi 2: Aplikasi di-restart dari cold start
      final container2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final state2 = await container2.read(serviceComponentsProvider.future);
      expect(state2.any((c) => c.id == 'comp_custom_rantai'), isTrue);
      final restoredItem = state2.firstWhere((c) => c.id == 'comp_custom_rantai');
      expect(restoredItem.nama, 'Rantai & Gir Paket SSS');
      expect(restoredItem.intervalKm, 18000);
      expect(restoredItem.isCustom, isTrue);

      container2.dispose();
    });
  });
}
