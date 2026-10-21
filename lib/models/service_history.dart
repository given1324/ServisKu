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

  /// Validasi apakah model memiliki field yang valid
  bool get isValid =>
      id.isNotEmpty &&
      jenisServis.trim().isNotEmpty &&
      odometer >= 0 &&
      totalBiaya >= 0;

  /// Memvalidasi field model dan melempar FormatException jika invalid
  void validate() {
    if (id.trim().isEmpty) {
      throw const FormatException('Data servis invalid: atribut "id" tidak boleh kosong');
    }
    if (jenisServis.trim().isEmpty) {
      throw const FormatException('Data servis invalid: atribut "jenisServis" tidak boleh kosong');
    }
    if (odometer < 0) {
      throw const FormatException('Data servis invalid: atribut "odometer" tidak boleh bernilai negatif');
    }
    if (totalBiaya < 0) {
      throw const FormatException('Data servis invalid: atribut "totalBiaya" tidak boleh bernilai negatif');
    }
  }

  factory ServiceHistory.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('id') || map['id'] == null || (map['id'] as String).trim().isEmpty) {
      throw const FormatException('Data servis invalid: atribut "id" hilang atau kosong');
    }
    if (!map.containsKey('jenisServis') || map['jenisServis'] == null || (map['jenisServis'] as String).trim().isEmpty) {
      throw const FormatException('Data servis invalid: atribut "jenisServis" hilang atau kosong');
    }
    if (!map.containsKey('odometer') || map['odometer'] == null || map['odometer'] is! num || (map['odometer'] as num) < 0) {
      throw const FormatException('Data servis invalid: atribut "odometer" tidak valid atau bernilai negatif');
    }
    if (!map.containsKey('totalBiaya') || map['totalBiaya'] == null || map['totalBiaya'] is! num || (map['totalBiaya'] as num) < 0) {
      throw const FormatException('Data servis invalid: atribut "totalBiaya" tidak valid atau bernilai negatif');
    }
    if (!map.containsKey('createdAt') || map['createdAt'] == null) {
      throw const FormatException('Data servis invalid: atribut "createdAt" hilang');
    }

    return ServiceHistory(
      id: (map['id'] as String).trim(),
      jenisServis: (map['jenisServis'] as String).trim(),
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
