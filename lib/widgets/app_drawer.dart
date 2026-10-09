import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/dashboard_screen.dart';
import '../screens/repairs_list_screen.dart';
import '../screens/add_repair_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/history_screen.dart';

/// Identifies which drawer item should be highlighted as active.
enum DrawerItem { home, repairs, addRepair, history, analytics, settings }

class AppDrawer extends StatelessWidget {
  final DrawerItem activeItem;

  const AppDrawer({super.key, this.activeItem = DrawerItem.home});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.navyBackground,
      width: 260,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildItem(
              context,
              icon: Icons.home_rounded,
              label: 'Home',
              item: DrawerItem.home,
            ),
            _buildItem(
              context,
              icon: Icons.grid_view_rounded,
              label: 'Repairs',
              item: DrawerItem.repairs,
            ),
            _buildItem(
              context,
              icon: Icons.add_circle_outline_rounded,
              label: 'Add Repair',
              item: DrawerItem.addRepair,
            ),
            _buildItem(
              context,
              icon: Icons.history_rounded,
              label: 'History',
              item: DrawerItem.history,
            ),
            _buildItem(
              context,
              icon: Icons.bar_chart_rounded,
              label: 'Analytics',
              item: DrawerItem.analytics,
            ),
            _buildItem(
              context,
              icon: Icons.settings_outlined,
              label: 'Settings',
              item: DrawerItem.settings,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build_rounded, color: AppColors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'FixLog',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DrawerItem item,
  }) {
    final bool active = item == activeItem;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: active ? AppColors.drawerActiveBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context); // close drawer
            if (item == activeItem) return; // already here

            switch (item) {
              case DrawerItem.home:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
                break;
              case DrawerItem.repairs:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RepairsListScreen()),
                );
                break;
              case DrawerItem.addRepair:
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddRepairScreen()),
                );
                break;
              case DrawerItem.history:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
                break;
              case DrawerItem.analytics:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                );
                break;
              case DrawerItem.settings:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                break;
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: active ? AppColors.white : AppColors.drawerInactiveText,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? AppColors.white : AppColors.drawerInactiveText,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
