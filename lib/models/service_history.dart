class ServiceHistory {
  final String id;
  final String jenisServis;
  final int odometer;
  final int totalBiaya;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String status;

  ServiceHistory({
    required this.id,
    required this.jenisServis,
    required this.odometer,
    required this.totalBiaya,
    required this.createdAt,
    this.completedAt,
    required this.status,
  });

  ServiceHistory copyWith({
    String? id,
    String? jenisServis,
    int? odometer,
    int? totalBiaya,
    DateTime? createdAt,
    DateTime? completedAt,
    String? status,
  }) {
    return ServiceHistory(
      id: id ?? this.id,
      jenisServis: jenisServis ?? this.jenisServis,
      odometer: odometer ?? this.odometer,
      totalBiaya: totalBiaya ?? this.totalBiaya,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
    );
  }
}
