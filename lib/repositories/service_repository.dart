import '../models/service_history.dart';

class ServiceRepository {
  // Simulasi pemanggilan API dengan delay
  Future<List<ServiceHistory>> fetchServiceHistory() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulasi network delay
    
    // Kembalikan daftar data servis kendaraan
    return [];
  }

  // Simulasi fungsi simpan data ke API
  Future<void> addServiceHistory(ServiceHistory service) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulasi loading API
  }

  // Simulasi fungsi update data ke API
  Future<void> updateServiceHistory(ServiceHistory service) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulasi loading API
  }

  // Simulasi fungsi hapus data ke API
  Future<void> deleteServiceHistory(String id) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulasi loading API
  }
}
