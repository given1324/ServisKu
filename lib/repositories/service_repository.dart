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
        date: DateTime.now().subtract(const Duration(days: 30)),
        status: 'Selesai',
      ),
      ServiceHistory(
        id: '2',
        jenisServis: 'Ganti Kampas Rem Depan',
        odometer: 20100,
        totalBiaya: 85000,
        date: DateTime.now().subtract(const Duration(days: 5)),
        status: 'Selesai',
      ),
    ];
  }

  // Simulasi fungsi simpan data ke API
  Future<void> addServiceHistory(ServiceHistory service) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulasi loading API
    // Pada implementasi nyata, di sini akan dilakukan HTTP POST request
  }
}
