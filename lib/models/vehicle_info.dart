import 'dart:convert';

class VehicleInfo {
  final String namaMotor;
  final String platNomor;
  final int tahun;

  const VehicleInfo({
    required this.namaMotor,
    required this.platNomor,
    required this.tahun,
  });

  static const VehicleInfo defaultVehicle = VehicleInfo(
    namaMotor: 'Honda Vario 160',
    platNomor: 'B 1234 XYZ',
    tahun: 2023,
  );

  VehicleInfo copyWith({
    String? namaMotor,
    String? platNomor,
    int? tahun,
  }) {
    return VehicleInfo(
      namaMotor: namaMotor ?? this.namaMotor,
      platNomor: platNomor ?? this.platNomor,
      tahun: tahun ?? this.tahun,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'namaMotor': namaMotor,
      'platNomor': platNomor,
      'tahun': tahun,
    };
  }

  factory VehicleInfo.fromMap(Map<String, dynamic> map) {
    return VehicleInfo(
      namaMotor: map['namaMotor'] as String? ?? defaultVehicle.namaMotor,
      platNomor: map['platNomor'] as String? ?? defaultVehicle.platNomor,
      tahun: (map['tahun'] as num?)?.toInt() ?? defaultVehicle.tahun,
    );
  }

  String toJson() => json.encode(toMap());

  factory VehicleInfo.fromJson(String source) =>
      VehicleInfo.fromMap(json.decode(source) as Map<String, dynamic>);
}
