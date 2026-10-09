import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/repair.dart';
import 'email_service.dart';
import 'activity_service.dart';

/// One entry in a repair's status-history timeline (Firestore subcollection
/// at `repairs/{docId}/history`).
class RepairHistoryEvent {
  final String title;
  final String? description;
  final DateTime? timestamp;

  const RepairHistoryEvent({
    required this.title,
    this.description,
    this.timestamp,
  });

  factory RepairHistoryEvent.fromFirestore(Map<String, dynamic> data) {
    final ts = data['timestamp'];
    return RepairHistoryEvent(
      title: (data['title'] as String?) ?? '',
      description: data['description'] as String?,
      timestamp: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class RepairService {
  RepairService._();
  static final RepairService instance = RepairService._();

  final CollectionReference<Map<String, dynamic>> _repairs =
      FirebaseFirestore.instance.collection('repairs');

  final DocumentReference<Map<String, dynamic>> _counterDoc =
      FirebaseFirestore.instance.collection('counters').doc('repairs');

  /// Live list of all repairs, newest first. Screens filter/search
  /// client-side over this stream.
  Stream<List<Repair>> watchAll() {
    return _repairs.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Repair.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Live updates for a single repair (used by Repair Details so edits/
  /// status changes reflect immediately without manual refresh).
  Stream<Repair?> watchOne(String docId) {
    return _repairs.doc(docId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Repair.fromFirestore(doc.id, doc.data()!);
    });
  }

  /// Creates a new repair with an auto-incrementing ticket number
  /// (e.g. "#001"), an initial "Pending" status, and a "Created" history
  /// entry. Returns the new document's ID.
  Future<String> addRepair(Repair repair, {required String createdByUid}) async {
    final docRef = _repairs.doc();
    final actor = await ActivityService.instance.currentActorName();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final counterSnap = await transaction.get(_counterDoc);
      final currentCount = (counterSnap.data()?['count'] as int?) ?? 0;
      final nextCount = currentCount + 1;
      final ticketNumber = '#${nextCount.toString().padLeft(3, '0')}';

      transaction.set(_counterDoc, {'count': nextCount});

      transaction.set(docRef, {
        ...repair.toMap(),
        'ticketNumber': ticketNumber,
        'status': RepairStatus.pending.storageValue,
        'createdBy': createdByUid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final historyRef = docRef.collection('history').doc();
      transaction.set(historyRef, {
        'title': 'Created',
        'description': 'Repair record was created',
        'timestamp': FieldValue.serverTimestamp(),
      });

      transaction.set(
        ActivityService.instance.newDoc(),
        ActivityService.instance.buildData(
          type: ActivityType.created,
          repair: repair,
          ticketNumber: ticketNumber,
          repairDocId: docRef.id,
          status: RepairStatus.pending,
          message: 'Created',
          actorName: actor,
        ),
      );
    });

    return docRef.id;
  }

  /// Updates the editable fields of a repair (Edit Repair screen).
  Future<void> updateRepair(String docId, Map<String, dynamic> fields) async {
    await _repairs.doc(docId).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates status and appends a history entry in one atomic batch write,
  /// then — if the repair has a customer email on file — sends a
  /// status-update email directly via EmailJS (see EmailService).
  ///
  /// Returns true if an email was actually sent, false if there was no
  /// email on file, EmailJS isn't configured yet, or sending failed.
  /// Sending happens after the Firestore write succeeds, and a failure
  /// here never throws — the status update itself always completes.
  Future<bool> updateStatus(
    Repair repair, {
    required RepairStatus newStatus,
    String? note,
  }) async {
    final docRef = _repairs.doc(repair.docId);
    final batch = FirebaseFirestore.instance.batch();

    batch.update(docRef, {
      'status': newStatus.storageValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final historyRef = docRef.collection('history').doc();
    batch.set(historyRef, {
      'title': newStatus.label,
      'description': (note != null && note.trim().isNotEmpty)
          ? note.trim()
          : 'Status changed to ${newStatus.label}',
      'timestamp': FieldValue.serverTimestamp(),
    });

    final ActivityType activityType;
    final String activityMessage;
    switch (newStatus) {
      case RepairStatus.completed:
        activityType = ActivityType.completed;
        activityMessage = 'Completed';
        break;
      case RepairStatus.cancelled:
        activityType = ActivityType.cancelled;
        activityMessage = 'Cancelled by technician';
        break;
      default:
        activityType = ActivityType.statusUpdated;
        activityMessage = 'Status updated';
    }
    final actor = await ActivityService.instance.currentActorName();
    batch.set(
      ActivityService.instance.newDoc(),
      ActivityService.instance.buildData(
        type: activityType,
        repair: repair,
        ticketNumber: repair.id,
        repairDocId: repair.docId,
        status: newStatus,
        message: activityMessage,
        actorName: actor,
      ),
    );

    await batch.commit();

    final email = repair.customerEmail;
    if (email == null || email.trim().isEmpty) return false;

    return EmailService.instance.sendStatusUpdateEmail(
      toEmail: email.trim(),
      customerName: repair.customerName,
      repairId: repair.id,
      deviceName: repair.deviceName,
      statusLabel: newStatus.label,
      note: note,
    );
  }

  /// Live history timeline for a repair, oldest first (matches the
  /// Repair History screen's top-to-bottom timeline).
  Stream<List<RepairHistoryEvent>> watchHistory(String docId) {
    return _repairs
        .doc(docId)
        .collection('history')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => RepairHistoryEvent.fromFirestore(d.data())).toList());
  }

  /// Deletes a repair and its history subcollection, and records a
  /// "deleted" entry in the activity log.
  Future<void> deleteRepair(Repair repair) async {
    final docRef = _repairs.doc(repair.docId);

    final historySnap = await docRef.collection('history').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in historySnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(docRef);
    final actor = await ActivityService.instance.currentActorName();
    batch.set(
      ActivityService.instance.newDoc(),
      ActivityService.instance.buildData(
        type: ActivityType.deleted,
        repair: repair,
        ticketNumber: repair.id,
        repairDocId: repair.docId,
        status: repair.status,
        message: 'Deleted',
        actorName: actor,
      ),
    );
    await batch.commit();
  }
}
