import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/repair.dart';
import '../services/repair_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_fab.dart';
import 'add_repair_screen.dart';

class _StatusSlice {
  final String label;
  final int value;
  final Color color;
  const _StatusSlice(this.label, this.value, this.color);
}

class _DeviceBar {
  final String label;
  final int value;
  const _DeviceBar(this.label, this.value);
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<_StatusSlice> _statusOverview(List<Repair> repairs) {
    int count(RepairStatus s) => repairs.where((r) => r.status == s).length;
    return [
      _StatusSlice('Pending', count(RepairStatus.pending), RepairStatus.pending.color),
      _StatusSlice('Diagnosing', count(RepairStatus.diagnosing), RepairStatus.diagnosing.color),
      _StatusSlice('In Progress', count(RepairStatus.inProgress), RepairStatus.inProgress.color),
      _StatusSlice('Ready for Pickup', count(RepairStatus.readyForPickup),
          RepairStatus.readyForPickup.color),
      _StatusSlice('Completed', count(RepairStatus.completed), RepairStatus.completed.color),
      _StatusSlice('Cancelled', count(RepairStatus.cancelled), RepairStatus.cancelled.color),
    ];
  }

  List<_DeviceBar> _topDevices(List<Repair> repairs) {
    const deviceTypes = ['Laptop', 'Phone', 'Desktop', 'Tablet'];
    final bars = <_DeviceBar>[];
    var othersCount = 0;
    for (final r in repairs) {
      if (!deviceTypes.contains(r.deviceName)) othersCount++;
    }
    for (final type in deviceTypes) {
      bars.add(_DeviceBar(type, repairs.where((r) => r.deviceName == type).length));
    }
    bars.add(_DeviceBar('Others', othersCount));
    bars.sort((a, b) => b.value.compareTo(a.value));
    return bars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      drawer: const AppDrawer(activeItem: DrawerItem.analytics),
      appBar: AppBar(
        backgroundColor: AppColors.navyBackground,
        elevation: 0,
        title: const Text(
          'Analytics',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<Repair>>(
          stream: RepairService.instance.watchAll(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              );
            }

            final repairs = snapshot.data!;
            final statusOverview = _statusOverview(repairs);
            final topDevices = _topDevices(repairs);
            final maxDeviceValue = topDevices.isEmpty
                ? 0
                : topDevices.map((d) => d.value).reduce((a, b) => a > b ? a : b);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalCard(repairs.length),
                  const SizedBox(height: 16),
                  _buildStatusOverviewCard(statusOverview),
                  const SizedBox(height: 16),
                  _buildTopDevicesCard(topDevices, maxDeviceValue),
                ],
              ),
            );
          },
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

  Widget _buildTotalCard(int total) {
    return Container(
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.groups_rounded, color: AppColors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Total Repairs',
            style: TextStyle(color: AppColors.greyText, fontSize: 13),
          ),
          const Spacer(),
          Text(
            '$total',
            style: TextStyle(
                color: AppColors.darkText, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverviewCard(List<_StatusSlice> statusOverview) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Overview',
            style: TextStyle(
                color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _DonutChartPainter(slices: statusOverview),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final slice in statusOverview) _buildLegendRow(slice),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(_StatusSlice slice) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              slice.label,
              style: TextStyle(color: AppColors.darkText, fontSize: 13),
            ),
          ),
          Text(
            '${slice.value}',
            style: TextStyle(
                color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDevicesCard(List<_DeviceBar> topDevices, int maxValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Devices',
            style: TextStyle(
                color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          for (final device in topDevices) _buildDeviceBarRow(device, maxValue),
        ],
      ),
    );
  }

  Widget _buildDeviceBarRow(_DeviceBar device, int maxValue) {
    final double fraction = maxValue == 0 ? 0 : device.value / maxValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(device.label,
                style: TextStyle(color: AppColors.darkText, fontSize: 13)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 14,
                backgroundColor: AppColors.inputBorder,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 22,
            child: Text(
              '${device.value}',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<_StatusSlice> slices;

  _DonutChartPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold(0, (sum, s) => sum + s.value);
    if (total == 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const strokeWidth = 16.0;
    double startAngle = -1.5708; // -90 degrees, start at top

    for (final slice in slices) {
      final sweep = (slice.value / total) * 6.28319; // 2*pi
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => false;
}
