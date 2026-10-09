import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/repair.dart';
import 'auth_service.dart';
import 'user_service.dart';

/// What kind of event an activity entry describes.
enum ActivityType { created, statusUpdated, completed, cancelled, deleted }

extension ActivityTypeX on ActivityType {
  String get storageValue => name;

  static ActivityType fromStorage(String? value) {
    return ActivityType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ActivityType.statusUpdated,
    );
  }
}

/// One entry in the History tab (a real event, e.g. "Repair #003 was
/// marked Completed by Juan"). Stored in Firestore.
///
/// Repair details are copied into each event on purpose: that way an entry
/// still reads correctly after the repair itself has been deleted.
class ActivityEvent {
  final String id;
  final ActivityType type;
  final String ticketNumber;
  final String customerName;
  final String deviceName;
  final String? brand;
  final String? model;
  final String? contactNumber;
  final RepairStatus? status;
  final String? repairDocId;
  final String message;
  final String? actorName;
  final DateTime? createdAt;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.ticketNumber,
    required this.customerName,
    required this.deviceName,
    this.brand,
    this.model,
    this.contactNumber,
    this.status,
    this.repairDocId,
    required this.message,
    this.actorName,
    this.createdAt,
  });

  /// "Acer Aspire 5" style text (empty if neither is known).
  String get deviceDetail =>
      [brand, model].where((s) => s != null && s.isNotEmpty).join(' ');

  factory ActivityEvent.fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    final statusRaw = data['status'] as String?;
    return ActivityEvent(
      id: id,
      type: ActivityTypeX.fromStorage(data['type'] as String?),
      // Fallbacks keep entries from the earlier notifications format readable.
      ticketNumber: (data['ticketNumber'] as String?) ?? (data['title'] as String?) ?? '—',
      customerName: (data['customerName'] as String?) ?? '',
      deviceName: (data['deviceName'] as String?) ?? '',
      brand: data['brand'] as String?,
      model: data['model'] as String?,
      contactNumber: data['contactNumber'] as String?,
      status: statusRaw == null ? null : RepairStatusX.fromStorage(statusRaw),
      repairDocId: data['repairDocId'] as String?,
      message: (data['message'] as String?) ?? (data['subtitle'] as String?) ?? '',
      actorName: data['actorName'] as String?,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// The activity log is shop-wide: every signed-in technician sees the same
/// events. Entries are written by RepairService inside the same Firestore
/// batch/transaction as the action they describe, so an entry only exists
/// if the action really happened.
///
/// The Firestore collection keeps its original name, `notifications`, so
/// existing data and security rules continue to work.
class ActivityService {
  ActivityService._();
  static final ActivityService instance = ActivityService._();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('notifications');

  String? _cachedActorName;

  /// The signed-in technician's display name (cached after the first lookup).
  Future<String> currentActorName() async {
    if (_cachedActorName != null) return _cachedActorName!;
    final user = AuthService.instance.currentUser;
    String name = user?.email ?? 'Technician';
    if (user != null) {
      try {
        final profile = await UserService.instance.fetchProfile(user.uid);
        if (profile != null && profile.name.trim().isNotEmpty) name = profile.name;
      } catch (_) {
        // Fall back to the email/'Technician' default.
      }
    }
    _cachedActorName = name;
    return name;
  }

  /// A fresh, empty document reference for a batch/transaction to write to.
  DocumentReference<Map<String, dynamic>> newDoc() => _col.doc();

  Map<String, dynamic> buildData({
    required ActivityType type,
    required Repair repair,
    required String ticketNumber,
    required String repairDocId,
    required RepairStatus status,
    required String message,
    required String actorName,
  }) {
    return {
      'type': type.storageValue,
      'ticketNumber': ticketNumber,
      'customerName': repair.customerName,
      'deviceName': repair.deviceName,
      'brand': repair.brand,
      'model': repair.model,
      'contactNumber': repair.contactNumber,
      'status': status.storageValue,
      'repairDocId': repairDocId,
      'message': message,
      'actorName': actorName,
      'createdBy': AuthService.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Most recent events first.
  Stream<List<ActivityEvent>> watchRecent({int limit = 200}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ActivityEvent.fromFirestore(d.id, d.data())).toList());
  }
}
