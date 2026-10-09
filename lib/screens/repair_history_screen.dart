import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/repair.dart';
import '../services/repair_service.dart';

class HistoryEvent {
  final String title;
  final String timestamp;
  final String description;
  final Color color;

  const HistoryEvent({
    required this.title,
    required this.timestamp,
    required this.description,
    required this.color,
  });
}

/// Picks a timeline dot color for a history entry's title. "Created" isn't
/// a RepairStatus, so it gets its own color; everything else tries to
/// match a known status label.
Color _colorForHistoryTitle(String title) {
  for (final status in RepairStatus.values) {
    if (status.label == title) return status.color;
  }
  return AppColors.primaryBlue; // "Created" and anything unrecognized
}

String _formatTimestamp(DateTime? dt) {
  if (dt == null) return 'Just now';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final period = dt.hour < 12 ? 'AM' : 'PM';
  final minute = dt.minute.toString().padLeft(2, '0');
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour12:$minute $period';
}

class RepairHistoryScreen extends StatelessWidget {
  final Repair repair;

  const RepairHistoryScreen({super.key, required this.repair});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navyBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Repair History',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repair ${repair.id}',
                  style: TextStyle(
                      color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${repair.customerName} • ${repair.deviceName}',
                  style: TextStyle(color: AppColors.greyText, fontSize: 13),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: AppColors.inputBorder),
                ),
                StreamBuilder<List<RepairHistoryEvent>>(
                  stream: RepairService.instance.watchHistory(repair.docId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Could not load history.',
                        style: TextStyle(color: AppColors.greyText, fontSize: 13),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primaryBlue),
                        ),
                      );
                    }

                    final events = snapshot.data!
                        .map((e) => HistoryEvent(
                              title: e.title,
                              timestamp: _formatTimestamp(e.timestamp),
                              description: e.description ?? '',
                              color: _colorForHistoryTitle(e.title),
                            ))
                        .toList();

                    if (events.isEmpty) {
                      return Text(
                        'No history yet.',
                        style: TextStyle(color: AppColors.greyText, fontSize: 13),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < events.length; i++)
                          _buildTimelineItem(events[i], isLast: i == events.length - 1),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(HistoryEvent event, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardSurface,
                  border: Border.all(color: event.color, width: 3),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: event.color.withOpacity(0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                        color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.timestamp,
                    style: TextStyle(color: AppColors.greyText, fontSize: 12),
                  ),
                  Text(
                    event.description,
                    style: TextStyle(color: AppColors.greyText, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
