import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/service_history.dart';
import '../providers/service_provider.dart';

class FormServisScreen extends ConsumerStatefulWidget {
  final ServiceHistory? existingService;
  const FormServisScreen({super.key, this.existingService});

  @override
  ConsumerState<FormServisScreen> createState() => _FormServisScreenState();
}

class _FormServisScreenState extends ConsumerState<FormServisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jenisServisController = TextEditingController();
  final _odometerController = TextEditingController();
  final _totalBiayaController = TextEditingController();
  final _catatanController = TextEditingController();
  
  late DateTime _selectedDate;
  String _status = 'Belum Selesai';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingService?.createdAt ?? DateTime.now();
    
    if (widget.existingService != null) {
      _jenisServisController.text = widget.existingService!.jenisServis;
      _odometerController.text = widget.existingService!.odometer.toString();
      _totalBiayaController.text = widget.existingService!.totalBiaya.toString();
      _status = widget.existingService!.status;
      // We don't have catatan in the model yet, but if we did, we'd load it here
    }
  }

  @override
  void dispose() {
    _jenisServisController.dispose();
    _odometerController.dispose();
    _totalBiayaController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isCompletingNow = _status == 'Selesai' && (widget.existingService?.status != 'Selesai');

      final serviceToSave = ServiceHistory(
        id: widget.existingService?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        jenisServis: _jenisServisController.text,
        odometer: int.parse(_odometerController.text),
        totalBiaya: int.parse(_totalBiayaController.text),
        createdAt: _selectedDate,
        completedAt: isCompletingNow ? DateTime.now() : widget.existingService?.completedAt,
        status: _status,
      );

      if (widget.existingService == null) {
        await ref.read(serviceHistoryProvider.notifier).addService(serviceToSave);
      } else {
        await ref.read(serviceHistoryProvider.notifier).updateService(serviceToSave);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan!')),
        );
        Navigator.pop(context); // Kembali ke dashboard
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

  Future<void> _deleteData() async {
    if (widget.existingService == null) return;
    
    // Show confirmation dialog before deleting
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Apakah Anda yakin ingin menghapus riwayat servis ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        await ref.read(serviceHistoryProvider.notifier).deleteService(widget.existingService!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil dihapus!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CATATAN KENDARAAN',
                    style: TextStyle(
                      color: Color(0xFF2E8C78),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.grey, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.existingService == null ? 'Tambah riwayat servis' : 'Edit riwayat servis',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 24),
              
              // Jenis Servis
              const Text('Jenis servis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _jenisServisController,
                decoration: InputDecoration(
                  hintText: 'Ganti Oli Mesin',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              
              // Tanggal & Odometer Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tanggal servis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                                ),
                                const Icon(Icons.calendar_today, size: 16, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Odometer (km)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _odometerController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '24560',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty || int.tryParse(value) == null) ? 'Tidak valid' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Total biaya
              const Text('Total biaya', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _totalBiayaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'Rp  ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14),
                  hintText: '185000',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) => (value == null || value.trim().isEmpty || int.tryParse(value) == null) ? 'Tidak valid' : null,
              ),
              const SizedBox(height: 16),
              
              // Catatan
              const Text.rich(
                TextSpan(
                  text: 'Catatan ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  children: [
                    TextSpan(
                      text: '(opsional)',
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Oli Motul 10W-40',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              
              // Status Dropdown (Kept to satisfy requirement to keep previous features)
              const Text('Status Servis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'Belum Selesai', child: Text('Belum Selesai')),
                  DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              
              // Bottom Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Hapus Button (Only when editing)
                  if (widget.existingService != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _deleteData,
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          label: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    
                  // Batal Button
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text('Batal', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  
                  // Simpan Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitData,
                    icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, color: Colors.white, size: 20),
                    label: const Text('Simpan catatan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135A4B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
