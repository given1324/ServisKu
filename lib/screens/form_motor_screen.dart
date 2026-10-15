import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_info.dart';
import '../providers/service_provider.dart';

class FormMotorScreen extends ConsumerStatefulWidget {
  final VehicleInfo currentVehicle;
  const FormMotorScreen({super.key, required this.currentVehicle});

  @override
  ConsumerState<FormMotorScreen> createState() => _FormMotorScreenState();
}

class _FormMotorScreenState extends ConsumerState<FormMotorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaMotorController;
  late TextEditingController _platNomorController;
  late TextEditingController _tahunController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaMotorController = TextEditingController(text: widget.currentVehicle.namaMotor);
    _platNomorController = TextEditingController(text: widget.currentVehicle.platNomor);
    _tahunController = TextEditingController(
      text: widget.currentVehicle.tahun > 0 ? widget.currentVehicle.tahun.toString() : '',
    );
  }

  @override
  void dispose() {
    _namaMotorController.dispose();
    _platNomorController.dispose();
    _tahunController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedVehicle = VehicleInfo(
        namaMotor: _namaMotorController.text.trim(),
        platNomor: _platNomorController.text.trim().toUpperCase(),
        tahun: int.tryParse(_tahunController.text.trim()) ?? widget.currentVehicle.tahun,
      );

      await ref.read(vehicleInfoProvider.notifier).updateVehicleInfo(updatedVehicle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informasi motor berhasil diperbarui!'),
            backgroundColor: Color(0xFF135A4B),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui motor: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF135A4B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.two_wheeler, color: Color(0xFF135A4B), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Informasi Motor',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF135A4B)),
                      ),
                      Text(
                        'Ubah nama, plat nomor, dan tahun motor',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nama Motor Field
              const Text('Nama / Tipe Motor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _namaMotorController,
                decoration: InputDecoration(
                  hintText: 'Misal: Honda Vario 160, Yamaha NMAX 155',
                  prefixIcon: const Icon(Icons.motorcycle, size: 20, color: Color(0xFF135A4B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama motor tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Plat Nomor Field
              const Text('Plat Nomor Kendaraan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _platNomorController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Misal: B 1234 XYZ',
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF135A4B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Plat nomor tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tahun Kendaraan Field
              const Text('Tahun Pembuatan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tahunController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Misal: 2023',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF135A4B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tahun tidak boleh kosong';
                  }
                  final year = int.tryParse(value.trim());
                  if (year == null || year < 1900 || year > 2100) {
                    return 'Masukkan tahun yang valid (contoh: 2022)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Actions Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal', style: TextStyle(color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135A4B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
