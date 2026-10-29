import 'dart:convert';

/// Model untuk Notifikasi Pengingat Servis (MVP Advance Feature 2)
class ServiceNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'reminder', 'success', 'warning'
  final String? componentName;
  final bool isUrgent;

  const ServiceNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'reminder',
    this.componentName,
    this.isUrgent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'componentName': componentName,
      'isUrgent': isUrgent,
    };
  }

  factory ServiceNotification.fromMap(Map<String, dynamic> map) {
    return ServiceNotification(
      id: map['id']?.toString() ?? 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: map['title']?.toString() ?? 'Pengingat Servis',
      message: map['message']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] == true,
      type: map['type']?.toString() ?? 'reminder',
      componentName: map['componentName']?.toString(),
      isUrgent: map['isUrgent'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ServiceNotification.fromJson(String source) =>
      ServiceNotification.fromMap(json.decode(source) as Map<String, dynamic>);

  ServiceNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    String? componentName,
    bool? isUrgent,
  }) {
    return ServiceNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      componentName: componentName ?? this.componentName,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}
