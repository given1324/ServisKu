import 'dart:convert';

class ServiceHistory {
  final String id;
  final String jenisServis;
  final int odometer;
  final int totalBiaya;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String status;
  final String? catatan;

  ServiceHistory({
    required this.id,
    required this.jenisServis,
    required this.odometer,
    required this.totalBiaya,
    required this.createdAt,
    this.completedAt,
    required this.status,
    this.catatan,
  });

  ServiceHistory copyWith({
    String? id,
    String? jenisServis,
    int? odometer,
    int? totalBiaya,
    DateTime? createdAt,
    DateTime? completedAt,
    String? status,
    String? catatan,
  }) {
    return ServiceHistory(
      id: id ?? this.id,
      jenisServis: jenisServis ?? this.jenisServis,
      odometer: odometer ?? this.odometer,
      totalBiaya: totalBiaya ?? this.totalBiaya,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jenisServis': jenisServis,
      'odometer': odometer,
      'totalBiaya': totalBiaya,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status,
      if (catatan != null) 'catatan': catatan,
    };
  }

  factory ServiceHistory.fromMap(Map<String, dynamic> map) {
    return ServiceHistory(
      id: map['id'] as String,
      jenisServis: map['jenisServis'] as String,
      odometer: (map['odometer'] as num).toInt(),
      totalBiaya: (map['totalBiaya'] as num).toInt(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      status: map['status'] as String? ?? 'Selesai',
      catatan: map['catatan'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory ServiceHistory.fromJson(String source) =>
      ServiceHistory.fromMap(json.decode(source) as Map<String, dynamic>);
}
