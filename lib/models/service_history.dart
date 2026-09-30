class ServiceHistory {
  final String id;
  final String jenisServis;
  final int odometer;
  final int totalBiaya;
  final DateTime date;
  final String status;

  ServiceHistory({
    required this.id,
    required this.jenisServis,
    required this.odometer,
    required this.totalBiaya,
    required this.date,
    required this.status,
  });
}
