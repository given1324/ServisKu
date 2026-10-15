import 'dart:convert';

class ServiceComponent {
  final String id;
  final String nama;
  final int intervalKm;
  final String deskripsi;
  final bool isCustom;

  const ServiceComponent({
    required this.id,
    required this.nama,
    required this.intervalKm,
    this.deskripsi = '',
    this.isCustom = false,
  });

  static const List<ServiceComponent> defaultPresets = [
    ServiceComponent(
      id: 'comp_oli_mesin',
      nama: 'Oli Mesin',
      intervalKm: 2500,
      deskripsi: 'Pelumas mesin utama, ganti berkala setiap 2.000 - 3.000 km',
    ),
    ServiceComponent(
      id: 'comp_oli_gardan',
      nama: 'Oli Gardan / Gear',
      intervalKm: 6000,
      deskripsi: 'Pelumas transmisi matic, ganti setiap 2-3x ganti oli mesin',
    ),
    ServiceComponent(
      id: 'comp_busi',
      nama: 'Busi',
      intervalKm: 8000,
      deskripsi: 'Pemantik pembakaran mesin, cek/ganti agar tarikan optimal',
    ),
    ServiceComponent(
      id: 'comp_filter_udara',
      nama: 'Filter Udara',
      intervalKm: 10000,
      deskripsi: 'Penyaring udara intake, ganti jika sudah kotor atau berdebu',
    ),
    ServiceComponent(
      id: 'comp_kampas_rem',
      nama: 'Kampas Rem',
      intervalKm: 12000,
      deskripsi: 'Komponen vital keselamatan pengereman depan & belakang',
    ),
    ServiceComponent(
      id: 'comp_cvt_vbelt',
      nama: 'V-Belt & Roller CVT',
      intervalKm: 24000,
      deskripsi: 'Transmisi sabuk matic, cek retakan dan keausan roller',
    ),
    ServiceComponent(
      id: 'comp_coolant',
      nama: 'Air Radiator (Coolant)',
      intervalKm: 15000,
      deskripsi: 'Cairan pendingin mesin radiator agar suhu tetap stabil',
    ),
  ];

  ServiceComponent copyWith({
    String? id,
    String? nama,
    int? intervalKm,
    String? deskripsi,
    bool? isCustom,
  }) {
    return ServiceComponent(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      intervalKm: intervalKm ?? this.intervalKm,
      deskripsi: deskripsi ?? this.deskripsi,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'intervalKm': intervalKm,
      'deskripsi': deskripsi,
      'isCustom': isCustom,
    };
  }

  factory ServiceComponent.fromMap(Map<String, dynamic> map) {
    return ServiceComponent(
      id: map['id'] as String,
      nama: map['nama'] as String,
      intervalKm: (map['intervalKm'] as num).toInt(),
      deskripsi: map['deskripsi'] as String? ?? '',
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ServiceComponent.fromJson(String source) =>
      ServiceComponent.fromMap(json.decode(source) as Map<String, dynamic>);
}
