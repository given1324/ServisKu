import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/service_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    // Membungkus aplikasi dengan ProviderScope dan menyuntikkan SharedPreferences yang sudah siap
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'ServisKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF135A4B)),
        scaffoldBackgroundColor: const Color(0xFFF7F9F9),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF135A4B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: authState.when(
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF135A4B),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pedal_bike, size: 64, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'ServisKu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
        error: (_, __) => const LoginScreen(),
        data: (user) {
          // Jika akun benar-benar sudah login, otomatis masuk ke dashboard
          if (user != null) {
            return const MainNavigationScreen();
          }
          // Jika belum login, wajib masuk lewat halaman login
          return const LoginScreen();
        },
      ),
    );
  }
}
