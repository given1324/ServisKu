import 'dart:convert';

/// Model pengguna untuk fitur Autentikasi (MVP Advance Feature 1)
class UserModel {
  final String id;
  final String nama;
  final String email;
  final String? nomorTelepon;
  final DateTime createdAt;
  final bool isGuest;

  const UserModel({
    required this.id,
    required this.nama,
    required this.email,
    this.nomorTelepon,
    required this.createdAt,
    this.isGuest = false,
  });

  // Pengguna demo bawaan
  static UserModel defaultUser = UserModel(
    id: 'usr-001',
    nama: 'Budi Rider',
    email: 'budi.rider@gmail.com',
    nomorTelepon: '081234567890',
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    isGuest: false,
  );

  static UserModel guestUser = UserModel(
    id: 'usr-guest',
    nama: 'Tamu (Guest Mode)',
    email: 'tamu@servisku.id',
    createdAt: DateTime.now(),
    isGuest: true,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'nomorTelepon': nomorTelepon,
      'createdAt': createdAt.toIso8601String(),
      'isGuest': isGuest,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? 'usr-001',
      nama: map['nama']?.toString() ?? 'Pengguna ServisKu',
      email: map['email']?.toString() ?? 'user@servisku.id',
      nomorTelepon: map['nomorTelepon']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isGuest: map['isGuest'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  UserModel copyWith({
    String? id,
    String? nama,
    String? email,
    String? nomorTelepon,
    DateTime? createdAt,
    bool? isGuest,
  }) {
    return UserModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      nomorTelepon: nomorTelepon ?? this.nomorTelepon,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}
