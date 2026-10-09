import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// A technician/user profile, stored in Firestore at
/// `users/{uid}` and created by an admin (there's no self-signup —
/// matches the "Don't have an account? Contact admin" login screen).
class TechnicianProfile {
  final String uid;
  final String name;
  final String email;
  final String? username;
  final String role;

  const TechnicianProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.username,
    required this.role,
  });

  bool get isAdmin => role.trim().toLowerCase() == 'admin';

  factory TechnicianProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return TechnicianProfile(
      uid: uid,
      name: (data['name'] as String?) ?? 'Technician',
      email: (data['email'] as String?) ?? '',
      username: data['username'] as String?,
      role: (data['role'] as String?) ?? 'Technician',
    );
  }
}

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  Future<TechnicianProfile?> fetchProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return TechnicianProfile.fromFirestore(uid, doc.data()!);
  }

  /// Looks up the email for a given username, for the "Email or Username"
  /// login field. Expects each user document to have a `username` field
  /// set by whoever creates the account (the admin).
  Future<String?> resolveEmailForUsername(String username) async {
    final query =
        await _users.where('username', isEqualTo: username.trim()).limit(1).get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.data()['email'] as String?;
  }

  /// Live updates to the profile (e.g. if an admin changes the
  /// technician's name/role while they're logged in).
  Stream<TechnicianProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return TechnicianProfile.fromFirestore(uid, doc.data()!);
    });
  }

  /// Whether the currently signed-in user's profile has the Admin role.
  Future<bool> isCurrentUserAdmin() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return false;
    final profile = await fetchProfile(uid);
    return profile?.isAdmin ?? false;
  }

  /// True if no other account already uses this username.
  Future<bool> isUsernameAvailable(String username) async {
    final query =
        await _users.where('username', isEqualTo: username.trim()).limit(1).get();
    return query.docs.isEmpty;
  }

  /// Writes the Firestore profile for a newly created technician account.
  /// Called right after AuthService.createTechnicianAccount.
  Future<void> createProfile({
    required String uid,
    required String name,
    required String email,
    String? username,
    required String role,
  }) async {
    await _users.doc(uid).set({
      'name': name.trim(),
      'email': email.trim(),
      if (username != null && username.trim().isNotEmpty) 'username': username.trim(),
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Every technician account, for the Manage Technicians screen.
  Stream<List<TechnicianProfile>> watchAllTechnicians() {
    return _users.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((d) => TechnicianProfile.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  /// Removes a technician's Firestore profile (used from Manage
  /// Technicians). This takes them out of the app's technician list and
  /// revokes any admin role tied to their profile, but — since account
  /// deletion requires the Firebase Admin SDK (Cloud Functions / Blaze
  /// plan, which this project doesn't use) — it does NOT delete their
  /// actual Firebase Auth login. To fully block them from signing in,
  /// also disable or delete their account in the Firebase Console under
  /// Authentication → Users.
  Future<void> deleteProfile(String uid) async {
    await _users.doc(uid).delete();
  }
}