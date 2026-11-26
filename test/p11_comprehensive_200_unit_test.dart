import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serviceku/models/service_component.dart';
import 'package:serviceku/models/service_history.dart';
import 'package:serviceku/models/service_notification.dart';
import 'package:serviceku/models/user_model.dart';
import 'package:serviceku/models/vehicle_info.dart';
import 'package:serviceku/models/workshop_model.dart';
import 'package:serviceku/repositories/profile_repository.dart';
import 'package:serviceku/utils/app_logger.dart';
import 'package:serviceku/utils/component_calculator.dart';
import 'package:serviceku/utils/validation.dart';

/// Suite Pengujian Komprehensif P11 (Mencapai Total > 200 Unit Tests).
/// Menguji seluruh perbaikan Bug (Issues #1 - #6) dan Fitur Baru (Issues #7 - #10).
///
/// CATATAN UNTUK SIMULASI UNIT TEST FAILED (TUGAS P11):
/// Ubah konstanta [simulateFailedUnitTest] di bawah ini menjadi `true`
/// untuk mendemonstrasikan efek ketika Unit Test GAGAL (Merah / Build Blocked),
/// lalu kembalikan ke `false` agar seluruh 200+ Unit Test LULUS (Hijau / Auto Build & Deploy).
const bool simulateFailedUnitTest = false;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // 0. SIMULASI UNIT TEST FAILED -> EFEK KE PIPELINE CI/CD (TUGAS P11)
  // ===========================================================================
  group('P11 Simulation - Pipeline Gatekeeper Test', () {
    test('0. Gatekeeper CI/CD: Memastikan seluruh aturan bisnis valid sebelum Auto Build & Deploy', () {
      if (simulateFailedUnitTest) {
        fail(
          'SIMULASI GAGAL (MERAH): Bug terdeteksi pada branch v1.0_dev! '
          'Tahap Auto-Build & Deploy ke Live DIBATALKAN secara otomatis oleh pipeline.',
        );
      }
      expect(simulateFailedUnitTest, isFalse);
    });
  });

  // ===========================================================================
  // 1. ISSUE #1 & #2 (BUG FIX): VALIDASI FORM MOTOR, SERVIS, KOMPONEN, & AUTH (60 UT)
  // ===========================================================================
  group('Issue #1 & #2 (Bug Fix): FormValidation Boundary & Edge Cases (60 Tests)', () {
    // 15 variasi tahun kendaraan valid (1990 - 2030)
    final validYears = [
      '1990', '1995', '2000', '2005', '2010',
      '2015', '2018', '2020', '2021', '2022',
      '2023', '2024', '2025', '2026', '2030',
    ];
    for (final y in validYears) {
      test('Validasi Tahun Kendaraan Valid: "$y" lulus tanpa error', () {
        expect(FormValidation.validateTahun(y), isNull);
      });
    }

    // 15 variasi tahun kendaraan invalid
    final invalidYears = [
      '', '   ', 'abc', '1899', '1800',
      '2101', '2500', '-2020', '20.24', '0',
      '999', '1500', '2200', 'tahun', 'null',
    ];
    for (final y in invalidYears) {
      test('Validasi Tahun Kendaraan Invalid: "$y" ditolak oleh validator', () {
        expect(FormValidation.validateTahun(y), isNotNull);
      });
    }

    // 15 variasi odometer & biaya valid
    final validNumbers = [
      '0', '100', '500', '1000', '2000',
      '4500', '8000', '10000', '12500', '15000',
      '20000', '25000', '50000', '75000', '100000',
    ];
    for (final n in validNumbers) {
      test('Validasi Angka Odometer & Biaya Valid: "$n" diterima', () {
        expect(FormValidation.validateOdometer(n), isNull);
        expect(FormValidation.validateTotalBiaya(n), isNull);
      });
    }

    // 15 variasi odometer & interval invalid
    final invalidNumbers = [
      '', ' ', '-1', '-500', 'abc',
      '12.5', '10,000', 'Rp 50000', 'NaN', '--10',
      '100km', 'null', 'true', '1e5', '0x10',
    ];
    for (final n in invalidNumbers) {
      test('Validasi Angka Odometer & Interval Invalid: "$n" ditolak', () {
        expect(FormValidation.validateOdometer(n), 'Tidak valid');
        expect(FormValidation.validateIntervalKm(n), isNotNull);
      });
    }
  });

  // ===========================================================================
  // 2. ISSUE #3 (BUG FIX): KALKULASI JADWAL KOMPONEN & FILTER STATUS SELESAI (45 UT)
  // ===========================================================================
  group('Issue #3 (Bug Fix): ComponentCalculator Interval, Warning & Overdue (45 Tests)', () {
    const oliComp = ServiceComponent(
      id: 'comp_oli',
      nama: 'Oli Mesin',
      intervalKm: 2000,
    );

    // 15 pengujian perhitungan sisa kilometer normal (Kondisi Baik)
    for (int i = 1; i <= 15; i++) {
      final currentOdo = 10000 + (i * 80); // 10080 .. 11200 (sisa > 500 km dari target 12000)
      test('Kalkulasi Normal #$i: Odo $currentOdo km -> target 12000 km (Kondisi Baik)', () {
        final history = [
          ServiceHistory(
            id: 'h-$i',
            jenisServis: 'Ganti Oli Mesin',
            odometer: 10000,
            totalBiaya: 65000,
            createdAt: DateTime(2026, 10, 1),
            status: 'Selesai',
          ),
        ];
        final status = ComponentCalculator.evaluate(
          component: oliComp,
          historyList: history,
          currentOdo: currentOdo,
        );
        expect(status.lastServicedKm, 10000);
        expect(status.nextServiceKm, 12000);
        expect(status.kmRemaining, 12000 - currentOdo);
        expect(status.isWarning, isFalse);
        expect(status.isOverdue, isFalse);
      });
    }

    // 15 pengujian zona Warning (sisa <= 500 km dan > 0 km)
    for (int i = 1; i <= 15; i++) {
      final currentOdo = 11500 + (i * 30); // 11530 .. 11950 (sisa 470 .. 50 km)
      test('Kalkulasi Warning #$i: Odo $currentOdo km -> sisa ${12000 - currentOdo} km (Segera Servis)', () {
        final history = [
          ServiceHistory(
            id: 'hw-$i',
            jenisServis: 'Ganti Oli Mesin',
            odometer: 10000,
            totalBiaya: 65000,
            createdAt: DateTime(2026, 10, 1),
            status: 'Selesai',
          ),
        ];
        final status = ComponentCalculator.evaluate(
          component: oliComp,
          historyList: history,
          currentOdo: currentOdo,
        );
        expect(status.isWarning, isTrue);
        expect(status.isOverdue, isFalse);
        expect(status.kmRemaining, 12000 - currentOdo);
      });
    }

    // 15 pengujian zona Overdue (currentOdo >= nextServiceKm) & mengabaikan status 'Belum Selesai'
    for (int i = 1; i <= 15; i++) {
      final currentOdo = 12000 + (i * 100); // 12100 .. 13500
      test('Kalkulasi Overdue & Pending Filter #$i: Odo $currentOdo km -> Overdue & Pending terdeteksi', () {
        final history = [
          ServiceHistory(
            id: 'hp-$i',
            jenisServis: 'Ganti Oli Mesin',
            odometer: currentOdo,
            totalBiaya: 65000,
            createdAt: DateTime(2026, 10, 5),
            status: 'Belum Selesai', // Belum selesai tidak boleh mereset target
          ),
          ServiceHistory(
            id: 'hc-$i',
            jenisServis: 'Ganti Oli Mesin',
            odometer: 10000,
            totalBiaya: 65000,
            createdAt: DateTime(2026, 10, 1),
            status: 'Selesai',
          ),
        ];
        final status = ComponentCalculator.evaluate(
          component: oliComp,
          historyList: history,
          currentOdo: currentOdo,
        );
        expect(status.lastServicedKm, 10000);
        expect(status.nextServiceKm, 12000);
        expect(status.isOverdue, isTrue);
        expect(status.hasPendingService, isTrue);
        expect(status.kmRemaining, 0);
      });
    }
  });

  // ===========================================================================
  // 3. ISSUE #4 & #5 (BUG FIX): KOORDINAT ASLI BENGKEL, JARAK JALAN & URL MAPS (35 UT)
  // ===========================================================================
  group('Issue #4 & #5 (Bug Fix): Workshop Real Coordinates, Distance & Direct Maps URL (35 Tests)', () {
    final bpnWorkshops = Workshop.generateForLocation(
      -1.2379,
      116.8529,
      'Balikpapan, Kalimantan Timur',
    );

    for (int i = 0; i < bpnWorkshops.length; i++) {
      final ws = bpnWorkshops[i];
      test('Bengkel Balikpapan #${i + 1} (${ws.nama}): Koordinat asli, jarak > 0, & URL Maps valid', () {
        final dist = ws.hitungJarak(-1.2379, 116.8529);
        expect(dist, greaterThan(0.0));
        expect(dist, lessThan(35.0));
        expect(ws.getGoogleMapsSearchUrl(), contains('https://www.google.com/maps/search/?api=1&query='));
        expect(ws.getGoogleMapsDirectionUrl(-1.2379, 116.8529), contains('destination=${ws.latitude},${ws.longitude}'));
      });
    }

    final smdWorkshops = Workshop.generateForLocation(
      -0.5022,
      117.1536,
      'Samarinda, Kalimantan Timur',
    );

    for (int i = 0; i < smdWorkshops.length; i++) {
      final ws = smdWorkshops[i];
      test('Bengkel Samarinda #${i + 1} (${ws.nama}): Koordinat asli, jarak > 0, & URL Maps valid', () {
        final dist = ws.hitungJarak(-0.5022, 117.1536);
        expect(dist, greaterThan(0.0));
        expect(dist, lessThan(35.0));
        expect(ws.getGoogleMapsDirectionUrl(-0.5022, 117.1536), contains('origin=-0.5022,117.1536'));
      });
    }

    // Pengujian 14 kota utama Indonesia di Workshop.indonesiaCities
    final cityEntries = Workshop.indonesiaCities.entries.take(14).toList();
    for (final entry in cityEntries) {
      test('Kota Indonesia "${entry.key}": Koordinat (${entry.value.lat}, ${entry.value.lng}) & daftar bengkel tersedia', () {
        final generated = Workshop.generateForLocation(
          entry.value.lat,
          entry.value.lng,
          entry.value.fullName,
        );
        expect(generated.length, greaterThanOrEqualTo(8));
      });
    }
  });

  // ===========================================================================
  // 4. ISSUE #6 - #10 (FEATURES & REFACTOR): MODELS, REPOSITORY & APPLOGGER (30 UT)
  // ===========================================================================
  group('Issue #6 - #10 (Features & Refactor): Models, ProfileRepository & AppLogger (30 Tests)', () {
    for (int i = 1; i <= 10; i++) {
      test('VehicleInfo & ProfileRepository Payload Mapping Test #$i', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = ProfileRepository(prefs: prefs);

        final info = VehicleInfo(
          namaMotor: 'Honda Vario 160 ABS #$i',
          platNomor: 'KT ${1000 + i} BPN',
          tahun: 2015 + i,
        );

        final payload = ProfileRepository.buildVehiclePayload(
          info: info,
          userEmail: 'user$i@servisku.id',
          userId: 'uid-$i',
        );
        expect(payload['nama_motor'], 'Honda Vario 160 ABS #$i');
        expect(payload['plat_nomor'], 'KT ${1000 + i} BPN');
        expect(payload['user_id'], 'uid-$i');

        final mapped = ProfileRepository.mapCloudRowToVehicle(payload);
        expect(mapped.namaMotor, info.namaMotor);
        expect(mapped.platNomor, info.platNomor);
        expect(mapped.tahun, info.tahun);

        await repo.saveVehicleInfo(info);
        final fetched = await repo.fetchVehicleInfo();
        expect(fetched.namaMotor, info.namaMotor);
      });
    }

    for (int i = 1; i <= 10; i++) {
      test('UserModel & ServiceNotification Serialization Test #$i', () {
        final user = UserModel(
          id: 'u-$i',
          nama: 'Rider ServisKu $i',
          email: 'rider$i@gmail.com',
          createdAt: DateTime(2026, 11, i),
          isGuest: i.isEven,
        );
        final restoredUser = UserModel.fromJson(user.toJson());
        expect(restoredUser.id, user.id);
        expect(restoredUser.email, user.email);
        expect(restoredUser.isGuest, user.isGuest);

        final notif = ServiceNotification(
          id: 'n-$i',
          title: 'Pengingat Servis #$i',
          message: 'Segera ganti komponen ke-$i',
          timestamp: DateTime(2026, 11, i, 8, 30),
          isRead: false,
          type: 'warning',
          componentName: 'Oli Mesin',
          isUrgent: true,
        );
        final restoredNotif = ServiceNotification.fromMap(notif.toMap());
        expect(restoredNotif.id, notif.id);
        expect(restoredNotif.isUrgent, isTrue);
        expect(restoredNotif.copyWith(isRead: true).isRead, isTrue);
      });
    }

    for (int i = 1; i <= 10; i++) {
      test('AppLogger Runtime Tracing Entry Serialization & Level Test #$i', () {
        final level = LogLevel.values[i % LogLevel.values.length];
        final entry = LogEntry(
          id: 'log-test-$i',
          timestamp: DateTime(2026, 11, 20, 8, 30, i),
          level: level,
          tag: 'MODULE_$i',
          message: 'Tracing runtime event ke-$i',
          detail: 'Detail trace #$i',
        );
        final restored = LogEntry.fromMap(entry.toMap());
        expect(restored.id, entry.id);
        expect(restored.level, level);
        expect(restored.tag, 'MODULE_$i');
        expect(restored.toConsoleString(), contains('[MODULE_$i]'));
      });
    }
  });
}
