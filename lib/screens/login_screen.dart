import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_provider.dart';

/// Halaman Autentikasi: Login (Email & Gmail) dan Registrasi Akun
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'budi.rider@gmail.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _namaController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isRegisterMode) {
        await ref.read(authProvider.notifier).register(
              _namaController.text,
              _emailController.text,
              _passwordController.text,
            );
      } else {
        await ref.read(authProvider.notifier).login(
              _emailController.text,
              _passwordController.text,
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF135A4B),
            content: Text(
              _isRegisterMode
                  ? 'Registrasi berhasil! Selamat datang di ServisKu.'
                  : 'Login berhasil! Selamat datang kembali.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        // Jika halaman ini dibuka melalui Navigator.push, tutup halaman
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Membuka opsi masuk melalui Akun Google / Gmail
  Future<void> _showGoogleSignInModal() async {
    final registeredUsers = await ref.read(authProvider.notifier).getRegisteredUsers();
    final customGmailController = TextEditingController();
    String? modalError;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEA4335),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Masuk dengan Akun Gmail',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Hanya akun yang telah terdaftar yang dapat masuk',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0)),

                    if (modalError != null) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modalError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Text(
                      'Pilih Akun Gmail Terdaftar:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),

                    // Daftar akun Gmail yang sudah terdaftar di aplikasi
                    if (registeredUsers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Belum ada akun yang terdaftar. Silakan registrasi terlebih dahulu.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      )
                    else
                      ...registeredUsers.map((u) {
                        final email = u['email']?.toString() ?? '';
                        final nama = u['nama']?.toString() ?? 'Pengguna';
                        return Card(
                          elevation: 0,
                          color: const Color(0xFFF8FAFC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE4F2EF),
                              child: Text(
                                nama.isNotEmpty ? nama[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Color(0xFF135A4B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              nama,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              email,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF135A4B)),
                            onTap: () async {
                              Navigator.pop(modalCtx);
                              await _handleGoogleLogin(email);
                            },
                          ),
                        );
                      }),

                    const SizedBox(height: 16),
                    const Text(
                      'Atau Masukkan Alamat Gmail Lain:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customGmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'contoh@gmail.com',
                              prefixIcon: const Icon(Icons.mail_outline, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF135A4B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final inputEmail = customGmailController.text.trim();
                            if (inputEmail.isEmpty || !inputEmail.contains('@')) {
                              setModalState(() {
                                modalError = 'Format email Gmail tidak valid.';
                              });
                              return;
                            }
                            final isFound = registeredUsers.any(
                              (u) => (u['email'] as String? ?? '').toLowerCase() == inputEmail.toLowerCase(),
                            );
                            if (!isFound) {
                              setModalState(() {
                                modalError = 'Akun Gmail ($inputEmail) belum terdaftar! Silakan mendaftar terlebih dahulu.';
                              });
                              return;
                            }
                            Navigator.pop(modalCtx);
                            await _handleGoogleLogin(inputEmail);
                          },
                          child: const Text('Masuk'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.person_add_outlined, size: 16, color: Color(0xFF135A4B)),
                        label: const Text(
                          'Daftar Akun Baru dengan Gmail',
                          style: TextStyle(
                            color: Color(0xFF135A4B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () {
                          final typedEmail = customGmailController.text.trim();
                          Navigator.pop(modalCtx);
                          setState(() {
                            _isRegisterMode = true;
                            _errorMessage = null;
                            if (typedEmail.isNotEmpty) {
                              _emailController.text = typedEmail;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleGoogleLogin(String email) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).loginWithGoogle(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF135A4B),
            content: Text(
              'Berhasil masuk dengan akun Google: $email',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF7F9F9);
    const cardColor = Colors.white;
    const accentColor = Color(0xFF135A4B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Header Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F2EF),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 2),
                  ),
                  child: const Icon(
                    Icons.pedal_bike,
                    color: accentColor,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ServisKu',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF135A4B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRegisterMode
                      ? 'Daftar akun untuk menyimpan catatan riwayat servis Anda'
                      : 'Silakan masuk terlebih dahulu untuk mengakses dashboard',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 28),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isRegisterMode ? 'Buat Akun Baru' : 'Masuk ke Akun Anda',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Error Message Banner jika akun belum terdaftar atau password salah
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade400),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Nama Field (Hanya saat registrasi)
                        if (_isRegisterMode) ...[
                          TextFormField(
                            controller: _namaController,
                            style: const TextStyle(color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: 'Nama Lengkap',
                              labelStyle: const TextStyle(color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nama lengkap wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            labelText: 'Alamat Email',
                            labelStyle: const TextStyle(color: Color(0xFF64748B)),
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Alamat email wajib diisi';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Format email tidak valid (contoh: user@gmail.com)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi',
                            labelStyle: const TextStyle(color: Color(0xFF64748B)),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kata sandi wajib diisi';
                            }
                            if (v.length < 6) {
                              return 'Kata sandi minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tombol Submit (Masuk / Daftar)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isRegisterMode ? 'Daftar Akun Baru' : 'Masuk ke Dashboard',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),

                        // Opsi Masuk lewat Gmail (Khusus Mode Login)
                        if (!_isRegisterMode) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'ATAU',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Tombol Masuk dengan Akun Google / Gmail
                          OutlinedButton(
                            onPressed: _isLoading ? null : _showGoogleSignInModal,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E293B),
                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEA4335),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'G',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Masuk dengan Akun Gmail',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Switch antara Login & Register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegisterMode = !_isRegisterMode;
                      _errorMessage = null;
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      text: _isRegisterMode ? 'Sudah punya akun terdaftar? ' : 'Belum punya akun? ',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      children: [
                        TextSpan(
                          text: _isRegisterMode ? 'Masuk di sini' : 'Daftar sekarang',
                          style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
