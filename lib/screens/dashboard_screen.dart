import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_fab.dart';
import 'repairs_list_screen.dart';
import 'add_repair_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/repair_service.dart';
import '../models/repair.dart';
import 'repair_details_screen.dart';
import 'account_settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      drawer: const AppDrawer(activeItem: DrawerItem.home),
      appBar: AppBar(
        backgroundColor: AppColors.navyBackground,
        elevation: 0,
        title: const Text(
          'FixLog',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(),
              const SizedBox(height: 16),
              StreamBuilder<List<Repair>>(
                stream: RepairService.instance.watchAll(),
                builder: (context, snapshot) {
                  final repairs = snapshot.data ?? const <Repair>[];

                  if (!snapshot.hasData) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primaryBlue),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatGrid(repairs),
                      const SizedBox(height: 20),
                      _buildRecentRepairsHeader(),
                      const SizedBox(height: 8),
                      if (repairs.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No repairs yet — tap + to add one.',
                              style: TextStyle(color: AppColors.greyText, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        for (final repair in repairs.take(5)) _buildRepairTile(repair),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AppFab(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddRepairScreen()),
          );
        },
      ),
    );
  }

  Widget _buildGreetingCard() {
    final user = AuthService.instance.currentUser;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.inputBorder,
            child: Icon(Icons.person, color: AppColors.greyText, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greetingForNow(),
                  style: TextStyle(color: AppColors.greyText, fontSize: 13),
                ),
                user == null
                    ? Text(
                        'Technician',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : StreamBuilder<TechnicianProfile?>(
                        stream: UserService.instance.watchProfile(user.uid),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data?.name ?? 'Technician',
                            style: TextStyle(
                              color: AppColors.darkText,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.greyText),
        ],
      ),
      ),
    );
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _buildStatGrid(List<Repair> repairs) {
    final total = repairs.length;
    final pending = repairs.where((r) => r.status == RepairStatus.pending).length;
    final inProgress = repairs.where((r) => r.status == RepairStatus.inProgress).length;
    final completed = repairs.where((r) => r.status == RepairStatus.completed).length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _statCard(
          icon: Icons.build_rounded,
          label: 'Total Repairs',
          value: '$total',
          color: AppColors.statBlue,
          bgColor: AppColors.statBlueBg,
        ),
        _statCard(
          icon: Icons.access_time_rounded,
          label: 'Pending',
          value: '$pending',
          color: AppColors.statOrange,
          bgColor: AppColors.statOrangeBg,
        ),
        _statCard(
          icon: Icons.autorenew_rounded,
          label: 'In Progress',
          value: '$inProgress',
          color: AppColors.statPurple,
          bgColor: AppColors.statPurpleBg,
        ),
        _statCard(
          icon: Icons.check_circle_rounded,
          label: 'Completed',
          value: '$completed',
          color: AppColors.statGreen,
          bgColor: AppColors.statGreenBg,
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRepairsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Repairs',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RepairsListScreen()),
            );
          },
          child: Text(
            'View All',
            style: TextStyle(color: AppColors.primaryBlue, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildRepairTile(Repair repair) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RepairDetailsScreen(repair: repair)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(repair.icon, color: AppColors.greyText, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${repair.id} ${repair.deviceName}',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    repair.customerName,
                    style: TextStyle(color: AppColors.greyText, fontSize: 12),
                  ),
                ],
              ),
            ),
            StatusBadge(status: repair.status),
          ],
        ),
      ),
    );
  }
}

