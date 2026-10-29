import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_provider.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'workshop_map_screen.dart';

/// Layar Navigasi Utama dengan Bottom Navigation Bar (Gaya Referensi)
class MainNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF7F9F9);
    const navBarColor = Colors.white;
    const activeColor = Color(0xFF135A4B);
    const inactiveColor = Color(0xFF64748B);

    final notifList = ref.watch(notificationProvider).value ?? [];
    final unreadNotifs = notifList.where((n) => !n.isRead).length;

    final screens = [
      const DashboardScreen(),
      const HistoryScreen(),
      const WorkshopMapScreen(),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBarColor,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.pedal_bike,
                  label: 'Kendaraan',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.history_rounded,
                  label: 'Riwayat',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.build_circle_outlined,
                  label: 'Bengkel',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifikasi',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  badgeCount: unreadNotifs,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  label: 'Akun',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
