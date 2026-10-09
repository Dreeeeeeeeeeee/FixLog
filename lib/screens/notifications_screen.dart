import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NotificationItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String timeAgo;

  const NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Sample notifications. Swap for real data from your backend/push service.
  List<NotificationItem> get _notifications => [
        NotificationItem(
          icon: Icons.location_on_rounded,
          iconColor: AppColors.statRed,
          iconBg: AppColors.statRedBg,
          title: 'Repair #005 status updated',
          subtitle: 'Now Ready for Pickup',
          timeAgo: '2h ago',
        ),
        NotificationItem(
          icon: Icons.person_add_alt_1_rounded,
          iconColor: AppColors.statBlue,
          iconBg: AppColors.statBlueBg,
          title: 'New repair added',
          subtitle: 'Juan Dela Cruz · Laptop',
          timeAgo: '4h ago',
        ),
        NotificationItem(
          icon: Icons.check_rounded,
          iconColor: AppColors.statGreen,
          iconBg: AppColors.statGreenBg,
          title: 'Repair #003 completed',
          subtitle: 'Rico Lim · Desktop',
          timeAgo: '1d ago',
        ),
        NotificationItem(
          icon: Icons.notifications_active_rounded,
          iconColor: AppColors.statOrange,
          iconBg: AppColors.statOrangeBg,
          title: 'Reminder',
          subtitle: 'Repair #002 is still pending',
          timeAgo: '1d ago',
        ),
      ];

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
          'Notifications',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notifications.length,
          itemBuilder: (context, index) => _buildNotificationTile(_notifications[index]),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem item) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(color: AppColors.greyText, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            item.timeAgo,
            style: TextStyle(color: AppColors.greyText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
