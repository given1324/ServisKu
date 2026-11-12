import '../models/service_component.dart';
import '../models/service_history.dart';

/// Hasil evaluasi jadwal servis satu komponen kendaraan.
class ComponentScheduleStatus {
  final int lastServicedKm;
  final int nextServiceKm;
  final int kmRemaining;
  final bool isOverdue;
  final bool isWarning;
  final bool hasPendingService;
  final double progress;

  const ComponentScheduleStatus({
    required this.lastServicedKm,
    required this.nextServiceKm,
    required this.kmRemaining,
    required this.isOverdue,
    required this.isWarning,
    required this.hasPendingService,
    required this.progress,
  });
}

/// Kalkulator status jadwal servis komponen (menghindari duplikasi perhitungan di UI & Notifier).
class ComponentCalculator {
  const ComponentCalculator._();

  /// Mengevaluasi status jadwal servis untuk satu komponen berdasarkan riwayat dan odometer terkini.
  static ComponentScheduleStatus evaluate({
    required ServiceComponent component,
    required List<ServiceHistory> historyList,
    required int currentOdo,
  }) {
    final completedServices = findCompletedServices(component, historyList);
    final pending = hasPendingService(component, historyList);

    final int lastServicedKm = completedServices.isNotEmpty
        ? completedServices.first.odometer
        : 0;

    final int nextServiceKm = calculateNextServiceKm(
      lastServicedKm: lastServicedKm,
      intervalKm: component.intervalKm,
    );

    final int kmRemaining = calculateKmRemaining(
      nextServiceKm: nextServiceKm,
      currentOdo: currentOdo,
    );

    final bool isOverdue = currentOdo >= nextServiceKm && currentOdo > 0;
    final bool isWarning = kmRemaining > 0 && kmRemaining <= 500;

    final double progress = calculateProgress(
      lastServicedKm: lastServicedKm,
      intervalKm: component.intervalKm,
      kmRemaining: kmRemaining,
      currentOdo: currentOdo,
      nextServiceKm: nextServiceKm,
    );

    return ComponentScheduleStatus(
      lastServicedKm: lastServicedKm,
      nextServiceKm: nextServiceKm,
      kmRemaining: kmRemaining,
      isOverdue: isOverdue,
      isWarning: isWarning,
      hasPendingService: pending,
      progress: progress,
    );
  }

  /// Mencari riwayat servis berstatus 'Selesai' yang cocok dengan nama komponen.
  static List<ServiceHistory> findCompletedServices(
    ServiceComponent component,
    List<ServiceHistory> historyList,
  ) {
    final targetName = component.nama.toLowerCase();
    return historyList
        .where(
          (s) =>
              s.status == 'Selesai' &&
              s.jenisServis.toLowerCase().contains(targetName),
        )
        .toList();
  }

  /// Mengecek apakah ada servis komponen ini yang masih berstatus 'Belum Selesai'.
  static bool hasPendingService(
    ServiceComponent component,
    List<ServiceHistory> historyList,
  ) {
    final targetName = component.nama.toLowerCase();
    return historyList.any(
      (s) =>
          s.status != 'Selesai' &&
          s.jenisServis.toLowerCase().contains(targetName),
    );
  }

  /// Menghitung target kilometer servis berikutnya.
  static int calculateNextServiceKm({
    required int lastServicedKm,
    required int intervalKm,
  }) {
    return lastServicedKm > 0 ? (lastServicedKm + intervalKm) : intervalKm;
  }

  /// Menghitung sisa kilometer menuju jadwal servis berikutnya.
  static int calculateKmRemaining({
    required int nextServiceKm,
    required int currentOdo,
  }) {
    return nextServiceKm > currentOdo ? (nextServiceKm - currentOdo) : 0;
  }

  /// Menghitung rasio progres pemakaian komponen (0.0 hingga 1.0).
  static double calculateProgress({
    required int lastServicedKm,
    required int intervalKm,
    required int kmRemaining,
    required int currentOdo,
    required int nextServiceKm,
  }) {
    if (intervalKm <= 0 || nextServiceKm <= 0) return 0.0;
    if (lastServicedKm > 0) {
      return ((intervalKm - kmRemaining) / intervalKm).clamp(0.0, 1.0);
    }
    return currentOdo > 0 ? (currentOdo / nextServiceKm).clamp(0.0, 1.0) : 0.0;
  }
}

