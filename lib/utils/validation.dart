/// Kumpulan fungsi validasi input murni (pure functions).
/// Memisahkan aturan bisnis input (validation) dari widget UI (ProfileForm / FormServisScreen).
class FormValidation {
  const FormValidation._();

  // ===========================================================================
  // 1. VALIDASI PROFIL KENDARAAN (ProfileForm / FormMotorScreen)
  // ===========================================================================

  /// Validasi nama atau tipe motor
  static String? validateNamaMotor(String? value) {
    if (_isBlank(value)) {
      return 'Nama motor tidak boleh kosong';
    }
    return null;
  }

  /// Validasi plat nomor kendaraan
  static String? validatePlatNomor(String? value) {
    if (_isBlank(value)) {
      return 'Plat nomor tidak boleh kosong';
    }
    return null;
  }

  /// Validasi tahun pembuatan motor (rentang 1900 - 2100)
  static String? validateTahun(String? value) {
    if (_isBlank(value)) {
      return 'Tahun tidak boleh kosong';
    }
    final year = int.tryParse(value!.trim());
    if (year == null || year < 1900 || year > 2100) {
      return 'Masukkan tahun yang valid (contoh: 2022)';
    }
    return null;
  }

  // ===========================================================================
  // 2. VALIDASI AUTENTIKASI & PROFIL PENGGUNA (LoginScreen)
  // ===========================================================================

  /// Validasi nama lengkap pengguna
  static String? validateNamaLengkap(String? value) {
    if (_isBlank(value)) {
      return 'Nama lengkap wajib diisi';
    }
    return null;
  }

  /// Validasi format alamat email
  static String? validateEmail(String? value) {
    if (_isBlank(value)) {
      return 'Alamat email wajib diisi';
    }
    final trimmed = value!.trim();
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      return 'Format email tidak valid (contoh: user@gmail.com)';
    }
    return null;
  }

  /// Validasi kata sandi (minimal 6 karakter)
  static String? validatePassword(String? value) {
    if (_isBlank(value)) {
      return 'Kata sandi wajib diisi';
    }
    if (value!.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  // ===========================================================================
  // 3. VALIDASI CATATAN SERVIS (FormServisScreen)
  // ===========================================================================

  /// Validasi nama / jenis servis
  static String? validateJenisServis(String? value) {
    if (_isBlank(value)) {
      return 'Tidak boleh kosong';
    }
    return null;
  }

  /// Validasi angka odometer (km)
  static String? validateOdometer(String? value) {
    return _validateNonNegativeInt(value);
  }

  /// Validasi angka total biaya servis (Rp)
  static String? validateTotalBiaya(String? value) {
    return _validateNonNegativeInt(value);
  }

  // ===========================================================================
  // 4. VALIDASI KOMPONEN SERVIS (ComponentsScreen)
  // ===========================================================================

  /// Validasi nama komponen servis berkala
  static String? validateNamaKomponen(String? value) {
    if (_isBlank(value)) {
      return 'Nama tidak boleh kosong';
    }
    return null;
  }

  /// Validasi interval kilometer komponen servis (> 0)
  static String? validateIntervalKm(String? value) {
    if (_isBlank(value)) {
      return 'Interval wajib diisi';
    }
    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) {
      return 'Masukkan angka km yang valid';
    }
    return null;
  }

  // ===========================================================================
  // HELPER INTERNAL KECIL (Single Responsibility)
  // ===========================================================================

  static bool _isBlank(String? value) {
    return value == null || value.trim().isEmpty;
  }

  static String? _validateNonNegativeInt(String? value) {
    if (_isBlank(value)) {
      return 'Tidak valid';
    }
    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed < 0) {
      return 'Tidak valid';
    }
    return null;
  }
}

