import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serviceku/models/service_history.dart';
import 'package:serviceku/repositories/service_repository.dart';
import 'package:serviceku/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pengujian Unit Test: Integrasi API & Vertical Slice (Minimal 6 Unit Test)', () {
    
    // -------------------------------------------------------------------------
    // 1. UNIT TEST: MODEL VALID
    // -------------------------------------------------------------------------
    test('1. Model Valid: JSON valid berhasil diparse ke ServiceHistory dan berstatus valid', () {
      final validJsonMap = {
        'id': 'srv-val-001',
        'jenisServis': 'Ganti Oli Mesin Shell Advance 10W-40',
        'odometer': 12000,
        'totalBiaya': 65000,
        'createdAt': '2026-10-21T09:30:00.000Z',
        'completedAt': '2026-10-21T10:15:00.000Z',
        'status': 'Selesai',
        'catatan': 'Servis berkala 12.000 km di bengkel resmi',
      };

      // Deserialisasi dari Map & JSON String
      final model = ServiceHistory.fromMap(validJsonMap);
      final fromJsonModel = ServiceHistory.fromJson(json.encode(validJsonMap));

      // Verifikasi seluruh field terpetakan secara presisi
      expect(model.id, 'srv-val-001');
      expect(model.jenisServis, 'Ganti Oli Mesin Shell Advance 10W-40');
      expect(model.odometer, 12000);
      expect(model.totalBiaya, 65000);
      expect(model.status, 'Selesai');
      expect(model.catatan, 'Servis berkala 12.000 km di bengkel resmi');
      expect(model.completedAt, isNotNull);

      // Verifikasi konsistensi serialisasi
      expect(fromJsonModel.id, model.id);
      expect(fromJsonModel.totalBiaya, model.totalBiaya);

      // Verifikasi validator model
      expect(model.isValid, isTrue);
      expect(() => model.validate(), returnsNormally);
    });

    // -------------------------------------------------------------------------
    // 2. UNIT TEST: MODEL INVALID
    // -------------------------------------------------------------------------
    test('2. Model Invalid: JSON/data invalid melempar FormatException atau terdeteksi invalid', () {
      // Kasus A: Field 'jenisServis' hilang / kosong
      final invalidMapMissingJenis = {
        'id': 'srv-inv-001',
        'jenisServis': '', // Kosong tidak diperbolehkan
        'odometer': 10000,
        'totalBiaya': 50000,
        'createdAt': '2026-10-21T09:30:00.000Z',
        'status': 'Selesai',
      };
      expect(
        () => ServiceHistory.fromMap(invalidMapMissingJenis),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('jenisServis'),
        )),
      );

      // Kasus B: Field 'odometer' bernilai negatif
      final invalidMapNegativeOdo = {
        'id': 'srv-inv-002',
        'jenisServis': 'Ganti Busi',
        'odometer': -500, // Negatif tidak valid
        'totalBiaya': 35000,
        'createdAt': '2026-10-21T09:30:00.000Z',
      };
      expect(
        () => ServiceHistory.fromMap(invalidMapNegativeOdo),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('odometer'),
        )),
      );

      // Kasus C: Field 'totalBiaya' bernilai negatif
      final invalidMapNegativeBiaya = {
        'id': 'srv-inv-003',
        'jenisServis': 'Servis CVT',
        'odometer': 15000,
        'totalBiaya': -20000, // Negatif tidak valid
        'createdAt': '2026-10-21T09:30:00.000Z',
      };
      expect(
        () => ServiceHistory.fromMap(invalidMapNegativeBiaya),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('totalBiaya'),
        )),
      );

      // Kasus D: Instansiasi objek model langsung dengan field invalid
      final invalidDirectModel = ServiceHistory(
        id: '', // ID kosong
        jenisServis: '   ', // Whitespace saja
        odometer: -1,
        totalBiaya: -100,
        createdAt: DateTime.now(),
        status: 'Belum Selesai',
      );
      expect(invalidDirectModel.isValid, isFalse);
      expect(() => invalidDirectModel.validate(), throwsA(isA<FormatException>()));
    });

    // -------------------------------------------------------------------------
    // 3. UNIT TEST: API SUKSES (Loading & Penyimpanan ke Backend)
    // -------------------------------------------------------------------------
    test('3. API Sukses: Backend mengembalikan HTTP 200/201 dan data berhasil dimuat/disimpan', () async {
      final mockDataList = [
        {
          'id': 'srv-api-101',
          'jenisServis': 'Servis Injeksi & Ganti Oli MPX',
          'odometer': 14500,
          'totalBiaya': 95000,
          'createdAt': '2026-10-20T08:00:00.000Z',
          'status': 'Selesai',
          'catatan': 'Tarikan motor kembali enteng',
        },
        {
          'id': 'srv-api-102',
          'jenisServis': 'Ganti Kampas Rem Belakang',
          'odometer': 14000,
          'totalBiaya': 60000,
          'createdAt': '2026-10-10T11:00:00.000Z',
          'status': 'Selesai',
        }
      ];

      // Setup Mock HTTP Client sukses 200 OK
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/services')) {
          return http.Response(
            json.encode(mockDataList),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.method == 'POST' && request.url.path.endsWith('/services')) {
          final payload = json.decode(request.body) as Map<String, dynamic>;
          return http.Response(
            json.encode(payload),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);
      final repository = ServiceRepository(apiService: apiService);

      // 1. Loading dari Backend (GET /services)
      final items = await repository.fetchServiceHistory();
      expect(items.length, 2);
      expect(items.first.id, 'srv-api-101');
      expect(items.first.jenisServis, 'Servis Injeksi & Ganti Oli MPX');
      expect(items.first.totalBiaya, 95000);

      // 2. Penyimpanan data ke Backend (POST /services)
      final newService = ServiceHistory(
        id: 'srv-api-103',
        jenisServis: 'Ganti Ban Belakang Maxxis',
        odometer: 15000,
        totalBiaya: 320000,
        createdAt: DateTime.now(),
        status: 'Selesai',
      );
      await expectLater(repository.addServiceHistory(newService), completes);
    });

    // -------------------------------------------------------------------------
    // 4. UNIT TEST: DATA KOSONG (Empty State dari Backend)
    // -------------------------------------------------------------------------
    test('4. Data Kosong: Backend mengembalikan HTTP 200 OK dengan payload array kosong []', () async {
      // Setup Mock HTTP Client mengembalikan array kosong []
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode([]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final repository = ServiceRepository(apiService: apiService);

      final items = await repository.fetchServiceHistory();

      // Verifikasi respons data kosong ditangani dengan tepat (empty state)
      expect(items, isNotNull);
      expect(items, isEmpty);
      expect(items.length, 0);
    });

    // -------------------------------------------------------------------------
    // 5. UNIT TEST: HTTP GAGAL (HTTP Error / Jaringan Bermasalah)
    // -------------------------------------------------------------------------
    test('5. HTTP Gagal: Backend mengembalikan status HTTP error (500/404) melempar ApiException', () async {
      // Kasus A: HTTP 500 Internal Server Error
      final mockClient500 = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'Internal Server Error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo500 = ServiceRepository(apiService: ApiService(client: mockClient500));
      expect(
        () => repo500.fetchServiceHistory(),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );

      // Kasus B: HTTP 404 Not Found
      final mockClient404 = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'Endpoint Not Found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo404 = ServiceRepository(apiService: ApiService(client: mockClient404));
      expect(
        () => repo404.fetchServiceHistory(),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );

      // Kasus C: HTTP Failure saat penyimpanan data (POST)
      final newService = ServiceHistory(
        id: 'srv-fail-001',
        jenisServis: 'Ganti Kampas Rem',
        odometer: 10000,
        totalBiaya: 50000,
        createdAt: DateTime.now(),
        status: 'Belum Selesai',
      );
      expect(
        () => repo500.addServiceHistory(newService),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });

    // -------------------------------------------------------------------------
    // 6. UNIT TEST: JSON RUSAK (Malformed / Corrupted Response)
    // -------------------------------------------------------------------------
    test('6. JSON Rusak: Backend mengembalikan HTTP 200 dengan payload JSON cacat melempar FormatException', () async {
      // Kasus A: Respons body memiliki sintaks JSON rusak/terpotong
      final mockClientMalformed = MockClient((request) async {
        return http.Response(
          '[{ "id": "1", "jenisServis": "Oli", "odometer": 1000, INCOMPLETE_SYNTAX',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repoMalformed = ServiceRepository(apiService: ApiService(client: mockClientMalformed));
      expect(
        () => repoMalformed.fetchServiceHistory(),
        throwsA(isA<FormatException>()),
      );

      // Kasus B: Respons body berupa dokumen HTML (misal error proxy/gateway) bukan JSON
      final mockClientHtml = MockClient((request) async {
        return http.Response(
          '<html><head><title>502 Bad Gateway</title></head><body><h1>Bad Gateway</h1></body></html>',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final repoHtml = ServiceRepository(apiService: ApiService(client: mockClientHtml));
      expect(
        () => repoHtml.fetchServiceHistory(),
        throwsA(isA<FormatException>()),
      );

      // Kasus C: Respons JSON valid tetapi bukan merupakan array (misal mengembalikan map)
      final mockClientNotArray = MockClient((request) async {
        return http.Response(
          json.encode({'status': 'ok', 'data': 'not a list'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repoNotArray = ServiceRepository(apiService: ApiService(client: mockClientNotArray));
      expect(
        () => repoNotArray.fetchServiceHistory(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
