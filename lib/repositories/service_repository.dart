import '../models/service_history.dart';

class ServiceRepository {
  // Simulasi pemanggilan API dengan delay
  Future<List<ServiceHistory>> fetchServiceHistory() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulasi network delay
    
    // Kembalikan daftar data servis kendaraan
    return [
      ServiceHistory(
        id: '1',
        jenisServis: 'Ganti Oli Mesin & Filter Oli',
        odometer: 15400,
        totalBiaya: 150000,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        completedAt: DateTime.now().subtract(const Duration(days: 29)),
        status: 'Selesai',
      ),
      ServiceHistory(
        id: '2',
        jenisServis: 'Ganti Kampas Rem Depan',
        odometer: 20100,
        totalBiaya: 85000,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        completedAt: null,
        status: 'Belum Selesai',
      ),
    ];
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
