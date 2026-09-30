import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_history.dart';
import '../providers/service_provider.dart';

class FormServisScreen extends ConsumerStatefulWidget {
  const FormServisScreen({super.key});

  @override
  ConsumerState<FormServisScreen> createState() => _FormServisScreenState();
}

class _FormServisScreenState extends ConsumerState<FormServisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jenisServisController = TextEditingController();
  final _odometerController = TextEditingController();
  final _totalBiayaController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _jenisServisController.dispose();
    _odometerController.dispose();
    _totalBiayaController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    // Kondisi 5: Validasi input pada TextFormField
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kondisi 6: Loading state pada tombol submit (disable tombol/tampilkan indikator)
    setState(() {
      _isLoading = true;
    });

    try {
      final newService = ServiceHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jenisServis: _jenisServisController.text,
        odometer: int.parse(_odometerController.text),
        totalBiaya: int.parse(_totalBiayaController.text),
        date: DateTime.now(),
        status: 'Selesai',
      );

      // Panggil method addService dari provider
      await ref.read(serviceHistoryProvider.notifier).addService(newService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan!')),
        );
        Navigator.pop(context); // Kembali ke dashboard setelah sukses
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Servis Kendaraan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _jenisServisController,
                decoration: const InputDecoration(
                  labelText: 'Jenis Servis (mis. Ganti Oli, Kampas Rem)',
                  border: OutlineInputBorder(),
                ),
                // Kondisi 5: Validasi input
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jenis servis tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _odometerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Odometer Saat Ini (km)',
                  border: OutlineInputBorder(),
                ),
                // Kondisi 5: Validasi input angka
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Odometer tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Masukkan angka odometer yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalBiayaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Biaya (Rp)',
                  border: OutlineInputBorder(),
                ),
                // Kondisi 5: Validasi input angka
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Total biaya tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Masukkan nominal angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Kondisi 6: Tombol Submit dengan disable dan indikator loading
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Data',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
