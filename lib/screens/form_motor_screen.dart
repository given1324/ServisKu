import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_info.dart';
import '../providers/service_provider.dart';
import '../utils/validation.dart';

/// Widget formulir profil kendaraan (ProfileForm).
/// Fokus murni pada input pengguna dan status UI (loading & feedback SnackBar).
/// Aturan validasi didelegasikan ke [FormValidation] dan request API ke [ProfileRepository].
class ProfileForm extends ConsumerStatefulWidget {
  final VehicleInfo currentVehicle;
  const ProfileForm({super.key, required this.currentVehicle});

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

/// Alias kompatibilitas untuk pemanggil lama yang menggunakan nama [FormMotorScreen].
class FormMotorScreen extends ProfileForm {
  const FormMotorScreen({super.key, required super.currentVehicle});
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaMotorController;
  late TextEditingController _platNomorController;
  late TextEditingController _tahunController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
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

  VehicleInfo _buildUpdatedVehicle() {
    return VehicleInfo(
      namaMotor: _namaMotorController.text.trim(),
      platNomor: _platNomorController.text.trim().toUpperCase(),
      tahun: int.tryParse(_tahunController.text.trim()) ?? widget.currentVehicle.tahun,
    );
  }

  void _setLoadingStatus(bool isLoading) {
    if (!mounted) return;
    setState(() {
      _isLoading = isLoading;
    });
  }

  void _showStatusSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF135A4B),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _setLoadingStatus(true);

    try {
      final updatedVehicle = _buildUpdatedVehicle();
      await ref.read(vehicleInfoProvider.notifier).updateVehicleInfo(updatedVehicle);

      if (mounted) {
        _showStatusSnackBar('Informasi motor berhasil diperbarui!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showStatusSnackBar('Gagal memperbarui motor: $e', isError: true);
    } finally {
      _setLoadingStatus(false);
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
                _buildDragHandle(),
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildInputField(
                  label: 'Nama / Tipe Motor',
                  controller: _namaMotorController,
                  hintText: 'Misal: Honda Vario 160, Yamaha NMAX 155',
                  prefixIcon: Icons.motorcycle,
                  validator: FormValidation.validateNamaMotor,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Plat Nomor Kendaraan',
                  controller: _platNomorController,
                  hintText: 'Misal: B 1234 XYZ',
                  prefixIcon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.characters,
                  validator: FormValidation.validatePlatNomor,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Tahun Pembuatan',
                  controller: _tahunController,
                  hintText: 'Misal: 2023',
                  prefixIcon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                  scrollPadding: const EdgeInsets.only(bottom: 140),
                  validator: FormValidation.validateTahun,
                ),
                const SizedBox(height: 28),
                _buildActionButtons(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          scrollPadding: scrollPadding,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF135A4B)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
    );
  }
}
