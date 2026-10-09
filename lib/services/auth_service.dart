import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

/// Thin wrapper around FirebaseAuth so the rest of the app never talks
/// to the Firebase SDK directly.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Emits the current user whenever sign-in state changes (including
  /// on app startup, once Firebase has restored any existing session).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Signs in with email + password.
  /// Throws a [FirebaseAuthException] on failure — callers should catch
  /// it and show `mapAuthError(e)` to the user.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Creates a brand-new Firebase Auth login (email + password) for a
  /// technician, **without** signing the admin out of their own session.
  ///
  /// Normally `createUserWithEmailAndPassword` immediately logs in as the
  /// new account, which would kick the admin out mid-task. To avoid that,
  /// this runs on a second, separate Firebase app instance that shares
  /// the same project but keeps its own login state — so the admin's
  /// session in the main app is never touched.
  ///
  /// Returns the new user's UID; callers should follow up with
  /// UserService.createProfile to write their Firestore profile.
  Future<String> createTechnicianAccount({
    required String email,
    required String password,
  }) async {
    FirebaseApp secondaryApp;
    try {
      secondaryApp = Firebase.app('AdminUserCreation');
    } on FirebaseException {
      secondaryApp = await Firebase.initializeApp(
        name: 'AdminUserCreation',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      await secondaryAuth.signOut();
      return uid;
    } catch (_) {
      // Make sure the throwaway session never lingers, even on failure.
      await secondaryAuth.signOut();
      rethrow;
    }
  }
}

/// Converts a [FirebaseAuthException] code into a friendly message.
String mapAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'That email address looks invalid.';
    case 'user-disabled':
      return 'This account has been disabled. Contact your admin.';
    case 'user-not-found':
      return 'No account found with that email or username.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    case 'email-already-in-use':
      return 'An account with that email already exists.';
    case 'weak-password':
      return 'That password is too weak — use at least 6 characters.';
    case 'operation-not-allowed':
      return 'Email/password sign-in isn\'t enabled for this project.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
