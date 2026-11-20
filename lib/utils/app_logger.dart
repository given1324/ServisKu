import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Level keparahan log untuk memudahkan pemfilteran saat tracing masalah di running mode.
enum LogLevel {
  info,
  success,
  warning,
  error,
}

/// Model satu entri log sistem saat aplikasi berjalan (on running mode).
class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? detail;

  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.detail,
  });

  String get levelLabel {
    switch (level) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.success:
        return 'SUCCESS';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  String get levelIcon {
    switch (level) {
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.success:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String toConsoleString() {
    final base = '[$formattedTime] $levelIcon [$levelLabel] [$tag] $message';
    if (detail != null && detail!.trim().isNotEmpty) {
      return '$base | Detail: $detail';
    }
    return base;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'tag': tag,
      'message': message,
      'detail': detail,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    final levelStr = map['level']?.toString() ?? 'info';
    final parsedLevel = LogLevel.values.firstWhere(
      (e) => e.name == levelStr,
      orElse: () => LogLevel.info,
    );
    return LogEntry(
      id: map['id']?.toString() ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      level: parsedLevel,
      tag: map['tag']?.toString() ?? 'SYSTEM',
      message: map['message']?.toString() ?? '',
      detail: map['detail']?.toString(),
    );
  }
}

/// Sistem pencatatan log terpusat (Runtime Log System) untuk membantu tracing
/// aktivitas dan masalah ketika program sedang berjalan (on running mode).
class AppLogger {
  AppLogger._();

  static const String storageKey = 'servisku_system_logs_v1';
  static const int maxLogs = 200;
  static SharedPreferences? _prefs;

  static final ValueNotifier<List<LogEntry>> logsNotifier =
      ValueNotifier<List<LogEntry>>([]);

  static List<LogEntry> get entries => List.unmodifiable(logsNotifier.value);

  /// Memuat riwayat log dari penyimpanan lokal saat aplikasi dinyalakan
  static Future<void> init([SharedPreferences? prefs]) async {
    try {
      _prefs = prefs ?? await SharedPreferences.getInstance();
      final raw = _prefs?.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as List<dynamic>;
        final restored = decoded
            .map((e) => LogEntry.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        logsNotifier.value = restored;
      }
    } catch (_) {}
    info('SYSTEM', 'AppLogger diinisialisasi (Runtime Tracing Mode Aktif)');
  }

  /// Mencatat log berlevel INFO (aktivitas normal, navigasi, request dimulai)
  static void info(String tag, String message, {String? detail}) {
    _record(LogLevel.info, tag, message, detail: detail);
  }

  /// Mencatat log berlevel SUCCESS (operasi CRUD, API, atau GPS berhasil)
  static void success(String tag, String message, {String? detail}) {
    _record(LogLevel.success, tag, message, detail: detail);
  }

  /// Mencatat log berlevel WARNING (fallback ke cache lokal, timeout ringan, validasi gagal)
  static void warning(String tag, String message, {Object? error}) {
    _record(LogLevel.warning, tag, message, detail: error?.toString());
  }

  /// Mencatat log berlevel ERROR (exception jaringan, kegagalan autentikasi, crash/error sistem)
  static void error(String tag, String message, {Object? error, StackTrace? stackTrace}) {
    String? detailText = error?.toString();
    if (stackTrace != null) {
      final firstLines = stackTrace.toString().split('\n').take(3).join(' | ');
      detailText = detailText != null ? '$detailText\n$firstLines' : firstLines;
    }
    _record(LogLevel.error, tag, message, detail: detailText);
  }

  static void _record(
    LogLevel level,
    String tag,
    String message, {
    String? detail,
  }) {
    final now = DateTime.now();
    final entry = LogEntry(
      id: 'log-${now.microsecondsSinceEpoch}',
      timestamp: now,
      level: level,
      tag: tag.toUpperCase(),
      message: message,
      detail: detail,
    );

    // 1. Cetak ke konsol terminal secara terstruktur
    debugPrint(entry.toConsoleString());

    // 2. Simpan ke memori reaktif (ring buffer maksimal 200 log terbaru)
    final updated = <LogEntry>[entry, ...logsNotifier.value];
    if (updated.length > maxLogs) {
      updated.removeRange(maxLogs, updated.length);
    }
    logsNotifier.value = updated;

    // 3. Persistensi asinkron ke SharedPreferences
    _persistAsync(updated);
  }

  static Future<void> _persistAsync(List<LogEntry> list) async {
    final p = _prefs;
    if (p == null) return;
    try {
      final encoded = json.encode(list.take(100).map((e) => e.toMap()).toList());
      await p.setString(storageKey, encoded);
    } catch (_) {}
  }

  /// Menghapus seluruh catatan log
  static Future<void> clear() async {
    logsNotifier.value = [];
    try {
      await _prefs?.remove(storageKey);
    } catch (_) {}
  }
}
