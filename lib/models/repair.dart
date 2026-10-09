import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

/// The possible states a repair ticket can be in.
enum RepairStatus { pending, diagnosing, inProgress, readyForPickup, completed, cancelled }

extension RepairStatusX on RepairStatus {
  /// Stable string stored in Firestore — doesn't change even if enum
  /// declaration order changes, unlike using `.index`.
  String get storageValue {
    switch (this) {
      case RepairStatus.inProgress:
        return 'inProgress';
      case RepairStatus.pending:
        return 'pending';
      case RepairStatus.completed:
        return 'completed';
      case RepairStatus.diagnosing:
        return 'diagnosing';
      case RepairStatus.readyForPickup:
        return 'readyForPickup';
      case RepairStatus.cancelled:
        return 'cancelled';
    }
  }

  static RepairStatus fromStorage(String? value) {
    switch (value) {
      case 'inProgress':
        return RepairStatus.inProgress;
      case 'pending':
        return RepairStatus.pending;
      case 'completed':
        return RepairStatus.completed;
      case 'diagnosing':
        return RepairStatus.diagnosing;
      case 'readyForPickup':
        return RepairStatus.readyForPickup;
      case 'cancelled':
        return RepairStatus.cancelled;
      default:
        return RepairStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case RepairStatus.inProgress:
        return 'In Progress';
      case RepairStatus.pending:
        return 'Pending';
      case RepairStatus.completed:
        return 'Completed';
      case RepairStatus.diagnosing:
        return 'Diagnosing';
      case RepairStatus.readyForPickup:
        return 'Ready for Pickup';
      case RepairStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case RepairStatus.inProgress:
        return AppColors.statBlue;
      case RepairStatus.pending:
        return AppColors.statRed;
      case RepairStatus.completed:
        return AppColors.statGreen;
      case RepairStatus.diagnosing:
        return AppColors.statPurple;
      case RepairStatus.readyForPickup:
        return AppColors.statOrange;
      case RepairStatus.cancelled:
        return AppColors.greyText;
    }
  }

  Color get bgColor {
    switch (this) {
      case RepairStatus.inProgress:
        return AppColors.statBlueBg;
      case RepairStatus.pending:
        return AppColors.statRedBg;
      case RepairStatus.completed:
        return AppColors.statGreenBg;
      case RepairStatus.diagnosing:
        return AppColors.statPurpleBg;
      case RepairStatus.readyForPickup:
        return AppColors.statOrangeBg;
      case RepairStatus.cancelled:
        return AppColors.inputBorder;
    }
  }

  IconData get statusIcon {
    switch (this) {
      case RepairStatus.inProgress:
        return Icons.autorenew_rounded;
      case RepairStatus.pending:
        return Icons.access_time_rounded;
      case RepairStatus.completed:
        return Icons.check_circle_rounded;
      case RepairStatus.diagnosing:
        return Icons.search_rounded;
      case RepairStatus.readyForPickup:
        return Icons.check_circle_rounded;
      case RepairStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }
}

/// Maps a device type string to a display icon, since IconData itself
/// isn't stored in Firestore — only the deviceName string is.
IconData iconForDeviceType(String deviceName) {
  switch (deviceName.toLowerCase()) {
    case 'laptop':
      return Icons.laptop_mac_rounded;
    case 'phone':
      return Icons.phone_android_rounded;
    case 'desktop':
      return Icons.desktop_windows_rounded;
    case 'tablet':
      return Icons.tablet_mac_rounded;
    default:
      return Icons.devices_other_rounded;
  }
}

/// A single repair ticket shown in the repairs list, and the fuller
/// record used by the details/edit/status/history screens.
///
/// [docId] is the Firestore document ID (used for updates/deletes/history).
/// [id] is the human-friendly ticket number shown in the UI (e.g. "#001").
class Repair {
  final String docId;
  final String id;
  final String deviceName;
  final String customerName;
  final RepairStatus status;
  final String? date;

  // Extra fields used by Repair Details / Edit Repair / Status Update.
  final String? contactNumber;
  final String? customerEmail;
  final String? brand;
  final String? model;
  final String? problemDescription;
  final String? estimatedCost;
  final String? actualCost;
  final String? dateReceived;
  final String? expectedCompletion;
  final String? notes;
  final DateTime? createdAt;

  const Repair({
    required this.docId,
    required this.id,
    required this.deviceName,
    required this.customerName,
    required this.status,
    this.date,
    this.contactNumber,
    this.customerEmail,
    this.brand,
    this.model,
    this.problemDescription,
    this.estimatedCost,
    this.actualCost,
    this.dateReceived,
    this.expectedCompletion,
    this.notes,
    this.createdAt,
  });

  /// Icon derived from [deviceName] — kept as a getter (not stored) so
  /// Firestore documents only need to hold plain data.
  IconData get icon => iconForDeviceType(deviceName);

  factory Repair.fromFirestore(String docId, Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    return Repair(
      docId: docId,
      id: (data['ticketNumber'] as String?) ?? '#000',
      deviceName: (data['deviceName'] as String?) ?? 'Other',
      customerName: (data['customerName'] as String?) ?? '',
      status: RepairStatusX.fromStorage(data['status'] as String?),
      date: data['date'] as String?,
      contactNumber: data['contactNumber'] as String?,
      customerEmail: data['customerEmail'] as String?,
      brand: data['brand'] as String?,
      model: data['model'] as String?,
      problemDescription: data['problemDescription'] as String?,
      estimatedCost: data['estimatedCost'] as String?,
      actualCost: data['actualCost'] as String?,
      dateReceived: data['dateReceived'] as String?,
      expectedCompletion: data['expectedCompletion'] as String?,
      notes: data['notes'] as String?,
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : null,
    );
  }

  /// Fields written on create/update. `ticketNumber`, `createdAt`, and
  /// `createdBy` are set separately by RepairService since they're either
  /// server-generated or set once at creation time.
  Map<String, dynamic> toMap() {
    return {
      'deviceName': deviceName,
      'customerName': customerName,
      'status': status.storageValue,
      'date': date,
      'contactNumber': contactNumber,
      'customerEmail': customerEmail,
      'brand': brand,
      'model': model,
      'problemDescription': problemDescription,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'dateReceived': dateReceived,
      'expectedCompletion': expectedCompletion,
      'notes': notes,
    };
  }
}

/// Small reusable status pill used on the repairs list and dashboard.
class StatusBadge extends StatelessWidget {
  final RepairStatus status;
  final bool showIcon;

  const StatusBadge({super.key, required this.status, this.showIcon = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.statusIcon, color: status.color, size: 13),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
