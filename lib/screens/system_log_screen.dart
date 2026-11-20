import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';

/// Layar Pemantau Log Sistem (Runtime Log Viewer).
/// Memudahkan tracing masalah langsung dari dalam aplikasi ketika program sudah running
/// (termasuk saat dijalankan sebagai Release APK di perangkat HP).
class SystemLogScreen extends StatefulWidget {
  const SystemLogScreen({super.key});

  @override
  State<SystemLogScreen> createState() => _SystemLogScreenState();
}

class _SystemLogScreenState extends State<SystemLogScreen> {
  LogLevel? _selectedLevel;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return const Color(0xFF2563EB);
      case LogLevel.success:
        return const Color(0xFF135A4B);
      case LogLevel.warning:
        return Colors.orange.shade800;
      case LogLevel.error:
        return Colors.red.shade700;
    }
  }

  Color _getLevelBgColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return const Color(0xFFEFF6FF);
      case LogLevel.success:
        return const Color(0xFFE4F2EF);
      case LogLevel.warning:
        return const Color(0xFFFFF7ED);
      case LogLevel.error:
        return const Color(0xFFFEF2F2);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF135A4B);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F9),
      appBar: AppBar(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Log Sistem (Runtime Tracing)',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Salin Semua Log',
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () async {
              final allLogs = AppLogger.entries
                  .map((e) => e.toConsoleString())
                  .join('\n');
              await Clipboard.setData(ClipboardData(text: allLogs));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: accentColor,
                    content: Text('Seluruh log berhasil disalin ke Clipboard!'),
                  ),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Bersihkan Log',
            icon: const Icon(Icons.delete_sweep_outlined, size: 22),
            onPressed: () async {
              await AppLogger.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Riwayat log sistem dibersihkan.')),
                );
              }
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<LogEntry>>(
        valueListenable: AppLogger.logsNotifier,
        builder: (context, logs, _) {
          final filtered = logs.where((entry) {
            if (_selectedLevel != null && entry.level != _selectedLevel) {
              return false;
            }
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final matchTag = entry.tag.toLowerCase().contains(q);
              final matchMsg = entry.message.toLowerCase().contains(q);
              final matchDetail = (entry.detail ?? '').toLowerCase().contains(q);
              return matchTag || matchMsg || matchDetail;
            }
            return true;
          }).toList();

          final errorCount = logs.where((e) => e.level == LogLevel.error).length;
          final warnCount = logs.where((e) => e.level == LogLevel.warning).length;

          return Column(
            children: [
              // Banner Ringkasan Status Runtime
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBadge('Total Log', '${logs.length}', accentColor),
                    _buildStatBadge('Warning', '$warnCount', Colors.orange.shade800),
                    _buildStatBadge('Error', '$errorCount', Colors.red.shade700),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari tag (AUTH, GPS, SUPABASE, PROFILE) atau pesan...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 18, color: accentColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),

              // Filter Chips Level Log
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('Semua', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('INFO', LogLevel.info),
                    const SizedBox(width: 8),
                    _buildFilterChip('SUCCESS', LogLevel.success),
                    const SizedBox(width: 8),
                    _buildFilterChip('WARN', LogLevel.warning),
                    const SizedBox(width: 8),
                    _buildFilterChip('ERROR', LogLevel.error),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Daftar Log
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada catatan log yang sesuai filter.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final color = _getLevelColor(item.level);
                          final bgColor = _getLevelBgColor(item.level);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.level == LogLevel.error
                                    ? Colors.red.shade300
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${item.levelIcon} ${item.levelLabel}',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.tag,
                                        style: const TextStyle(
                                          color: Color(0xFF334155),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      item.formattedTime,
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.message,
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (item.detail != null && item.detail!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.detail!,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, LogLevel? level) {
    final isSelected = _selectedLevel == level;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF135A4B),
      backgroundColor: Colors.white,
      onSelected: (_) => setState(() => _selectedLevel = level),
    );
  }
}
