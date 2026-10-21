import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/service_history.dart';

/// Exception khusus untuk kegagalan komunikasi dengan REST API
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status Code: $statusCode)' : ''}';
}

/// Service untuk menangani panggilan HTTP ke Backend API
class ApiService {
  final http.Client client;
  final String baseUrl;

  ApiService({
    http.Client? client,
    this.baseUrl = 'https://api.servisku.local/api',
  }) : client = client ?? SimulatedBackendClient();

  /// GET /services (Loading dari Backend)
  Future<List<ServiceHistory>> fetchServices() async {
    final uri = Uri.parse('$baseUrl/services');
    debugPrint('🌐 [API GET] Meminta data dari Backend: $uri');
    final http.Response response;

    try {
      response = await client.get(uri);
    } catch (e) {
      debugPrint('❌ [API GET ERROR] Gagal koneksi: $e');
      if (e is FormatException) rethrow;
      throw ApiException('Gagal terhubung ke server API: $e');
    }

    if (response.statusCode == 200) {
      final dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (e) {
        debugPrint('❌ [API GET ERROR] JSON rusak: ${response.body}');
        throw FormatException('Format JSON rusak dari server: ${response.body}');
      }

      if (decoded is List) {
        final list = decoded
            .map((item) => ServiceHistory.fromMap(item as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [API GET 200] Berhasil menerima ${list.length} catatan servis dari Backend');
        return list;
      } else {
        debugPrint('❌ [API GET ERROR] Payload bukan array JSON: $decoded');
        throw const FormatException('Payload respons bukan merupakan array JSON valid');
      }
    } else {
      debugPrint('❌ [API GET ERROR] Server error HTTP ${response.statusCode}');
      throw ApiException(
        'Gagal memuat data dari server',
        statusCode: response.statusCode,
      );
    }
  }

  /// POST /services (Penyimpanan data ke Backend)
  Future<ServiceHistory> createService(ServiceHistory service) async {
    service.validate();
    final uri = Uri.parse('$baseUrl/services');
    debugPrint('🌐 [API POST] Mengirim data baru ke Backend: ${service.jenisServis} (Rp ${service.totalBiaya})');
    final http.Response response;

    try {
      response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: service.toJson(),
      );
    } catch (e) {
      debugPrint('❌ [API POST ERROR] Gagal koneksi: $e');
      if (e is FormatException) rethrow;
      throw ApiException('Gagal terhubung ke server API: $e');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (e) {
        throw FormatException('Format JSON rusak dari server: ${response.body}');
      }

      debugPrint('✅ [API POST 201] Data berhasil tersimpan di Backend!');
      if (decoded is Map<String, dynamic>) {
        return ServiceHistory.fromMap(decoded);
      }
      return service;
    } else {
      debugPrint('❌ [API POST ERROR] Server error HTTP ${response.statusCode}');
      throw ApiException(
        'Gagal menyimpan data ke server',
        statusCode: response.statusCode,
      );
    }
  }

  /// PUT /services/:id (Update data di Backend)
  Future<ServiceHistory> updateService(ServiceHistory service) async {
    service.validate();
    final uri = Uri.parse('$baseUrl/services/${service.id}');
    debugPrint('🌐 [API PUT] Memperbarui data ID ${service.id} di Backend');
    final http.Response response;

    try {
      response = await client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: service.toJson(),
      );
    } catch (e) {
      debugPrint('❌ [API PUT ERROR] Gagal koneksi: $e');
      if (e is FormatException) rethrow;
      throw ApiException('Gagal terhubung ke server API: $e');
    }

    if (response.statusCode == 200) {
      final dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (e) {
        throw FormatException('Format JSON rusak dari server: ${response.body}');
      }

      debugPrint('✅ [API PUT 200] Data ID ${service.id} berhasil diperbarui di Backend');
      if (decoded is Map<String, dynamic>) {
        return ServiceHistory.fromMap(decoded);
      }
      return service;
    } else {
      debugPrint('❌ [API PUT ERROR] Server error HTTP ${response.statusCode}');
      throw ApiException(
        'Gagal memperbarui data di server',
        statusCode: response.statusCode,
      );
    }
  }

  /// DELETE /services/:id (Hapus data di Backend)
  Future<void> deleteService(String id) async {
    final uri = Uri.parse('$baseUrl/services/$id');
    debugPrint('🌐 [API DELETE] Menghapus data ID $id di Backend');
    final http.Response response;

    try {
      response = await client.delete(uri);
    } catch (e) {
      debugPrint('❌ [API DELETE ERROR] Gagal koneksi: $e');
      throw ApiException('Gagal terhubung ke server API: $e');
    }

    if (response.statusCode == 200 || response.statusCode == 204) {
      debugPrint('✅ [API DELETE] Data ID $id berhasil terhapus dari Backend');
    } else {
      debugPrint('❌ [API DELETE ERROR] Server error HTTP ${response.statusCode}');
      throw ApiException(
        'Gagal menghapus data dari server',
        statusCode: response.statusCode,
      );
    }
  }
}

/// SimulatedBackendClient: Implementasi [http.BaseClient] untuk mensimulasikan
/// REST API Server secara realistik saat aplikasi dijalankan mandiri (offline demo).
class SimulatedBackendClient extends http.BaseClient {
  static List<Map<String, dynamic>> _storage = [];

  static void resetStorage([List<Map<String, dynamic>>? initial]) {
    _storage = initial != null ? List<Map<String, dynamic>>.from(initial) : [];
  }

  static bool simulateError = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Delay simulasi singkat (50 ms) agar transisi loading tampak di antarmuka
    await Future.delayed(const Duration(milliseconds: 50));

    if (simulateError) {
      final body = json.encode({'message': 'Simulated 500 Internal Server Error'});
      return http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        500,
        headers: {'content-type': 'application/json'},
      );
    }

    final path = request.url.path;
    final method = request.method;

    // GET /services
    if (method == 'GET' && path.endsWith('/services')) {
      final body = json.encode(_storage);
      return http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // POST /services
    if (method == 'POST' && path.endsWith('/services')) {
      if (request is http.Request) {
        final data = json.decode(request.body) as Map<String, dynamic>;
        _storage.removeWhere((item) => item['id'] == data['id']);
        _storage.insert(0, data);
        final body = json.encode(data);
        return http.StreamedResponse(
          Stream.value(utf8.encode(body)),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
    }

    // PUT /services/:id
    if (method == 'PUT' && path.contains('/services/')) {
      final id = path.split('/').last;
      if (request is http.Request) {
        final data = json.decode(request.body) as Map<String, dynamic>;
        final index = _storage.indexWhere((item) => item['id'] == id);
        if (index != -1) {
          _storage[index] = data;
        } else {
          _storage.add(data);
        }
        final body = json.encode(data);
        return http.StreamedResponse(
          Stream.value(utf8.encode(body)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
    }

    // DELETE /services/:id
    if (method == 'DELETE' && path.contains('/services/')) {
      final id = path.split('/').last;
      _storage.removeWhere((item) => item['id'] == id);
      return http.StreamedResponse(
        Stream.value([]),
        204,
      );
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode(json.encode({'message': 'Not Found'}))),
      404,
      headers: {'content-type': 'application/json'},
    );
  }
}
