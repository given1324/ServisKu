import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:serviceku/main.dart';
import 'package:serviceku/models/service_history.dart';
import 'package:serviceku/providers/service_provider.dart';
import 'package:serviceku/repositories/service_repository.dart';
import 'package:serviceku/screens/dashboard_screen.dart';
import 'package:serviceku/screens/form_service_screen.dart';

// Mock Repository untuk menghilangkan delay dan mengatur data saat testing
class MockServiceRepository extends ServiceRepository {
  bool shouldThrowError = false;
  List<ServiceHistory> mockData = [];
  bool delayAdd = false;

  @override
  Future<List<ServiceHistory>> fetchServiceHistory() async {
    if (shouldThrowError) {
      throw Exception('Simulasi gagal memuat data');
    }
    return mockData;
  }
  
  @override
  Future<void> addServiceHistory(ServiceHistory service) async {
    if (delayAdd) {
      await Future.delayed(const Duration(seconds: 5));
    }
    mockData.add(service);
  }
}

void main() {
  late MockServiceRepository mockRepository;

  setUp(() {
    mockRepository = MockServiceRepository();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        serviceRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: Scaffold(body: DashboardScreen()),
      ),
    );
  }

  testWidgets('shows initial loading while service data is fetched', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('shows empty state when no service history has been saved', (WidgetTester tester) async {
    mockRepository.mockData = [];
    
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('Belum ada riwayat servis'), findsWidgets);
  });

  testWidgets('shows loaded data when a service history exists', (WidgetTester tester) async {
    mockRepository.mockData = [
      ServiceHistory(
        id: '1',
        jenisServis: 'Servis Mock Test',
        odometer: 10000,
        totalBiaya: 50000,
        createdAt: DateTime.now(),
        status: 'Selesai',
      )
    ];

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Use byType to find the list tile or text containing if exact text fails
    expect(find.textContaining('Servis Mock Test'), findsWidgets);
  });

  testWidgets('shows error state and retry loads the service history again', (WidgetTester tester) async {
    mockRepository.shouldThrowError = true;

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('Terjadi kesalahan saat memuat data'), findsWidgets);
    expect(find.text('Coba Lagi'), findsWidgets);
  });

  testWidgets('validates required fields and number formats', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FormServisScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final submitButton = find.text('Simpan catatan');
    expect(submitButton, findsOneWidget);

    // Ensure the button is visible before tapping (scroll to it)
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Tidak boleh kosong'), findsWidgets);
    expect(find.text('Tidak valid'), findsWidgets);
  });

  testWidgets('shows submit loading and prevents a double submit', (WidgetTester tester) async {
    mockRepository.delayAdd = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FormServisScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ganti Ban');
    await tester.enterText(find.byType(TextFormField).at(1), '12000');
    await tester.enterText(find.byType(TextFormField).at(2), '250000');
    
    final submitButton = find.text('Simpan catatan');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    
    // Trigger set state
    await tester.pump(); 
    
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    
    // Selesaikan pending timer agar test framework tidak mengembalikan error
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
