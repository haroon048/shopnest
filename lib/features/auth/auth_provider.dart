import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/services/notification_service.dart';
import '../../models/app_user.dart';

// Saara auth logic ek jagah. Koi screen Firebase se direct baat nahi karegi.
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  GoogleSignIn? _googleSignIn;

  AppUser? _user; // hamara user (Firestore wala)
  bool _isLoading = false; // button par spinner dikhane ke liye
  String? _error; // screen par dikhane ke liye error message

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isAdmin => _user?.role == 'admin';

  AuthProvider() {
    // App khulne par: agar pehle se login hai to user data load karo
    _auth.authStateChanges().listen((fbUser) async {
      if (fbUser == null) {
        _user = null;
      } else {
        try {
          await _loadUser(fbUser.uid);
        } on FirebaseException catch (error, stackTrace) {
          debugPrint('Failed to load signed-in user profile: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
        try {
          await NotificationService.saveToken();
        } catch (error, stackTrace) {
          debugPrint('Failed to save FCM token: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      notifyListeners();
    });
  }

  // Firestore se user ka document lao
  Future<void> _loadUser(String uid) async {
    _user = null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'user-profile-not-found',
        message: 'Firestore users/$uid profile document is missing.',
      );
    }
    _user = AppUser.fromMap(doc.data()!, uid);
  }

  void _start() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _done() {
    _isLoading = false;
    notifyListeners();
  }

  // Email se login. true = kamyab, false = nakam (error me wajah hogi)
  Future<bool> signIn(
    String email,
    String password, {
    String? expectedRole,
  }) async {
    _start();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUser(cred.user!.uid);
      if (expectedRole == 'admin' && !isAdmin) {
        await _auth.signOut();
        _user = null;
        _error = 'This account does not have admin access. Contact your '
            'project administrator to request the admin role.';
        return false;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _msg(e.code);
      return false;
    } on FirebaseException catch (e) {
      _user = null;
      await _auth.signOut();
      _error = _firebaseMsg(e);
      return false;
    } finally {
      _done();
    }
  }

  // Naya account banao + Firestore me user ka document banao
  Future<bool> signUp(String name, String email, String password) async {
    _start();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final appUser = AppUser(
        uid: cred.user!.uid,
        name: name,
        email: email,
        photoUrl: '',
        addresses: [],
        fcmTokens: [],
      );
      await _db.collection('users').doc(appUser.uid).set(appUser.toMap());
      _user = appUser;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _msg(e.code);
      return false;
    } on FirebaseException catch (e) {
      await _auth.signOut();
      _error = _firebaseMsg(e);
      return false;
    } finally {
      _done();
    }
  }

  // Google se login
  Future<bool> signInWithGoogle({String? expectedRole}) async {
    _start();
    try {
      const webClientId = String.fromEnvironment('GOOGLE_SIGN_IN_CLIENT_ID');
      if (kIsWeb && webClientId.isEmpty) {
        _error = 'Configure a web OAuth client ID to enable Google sign-in.';
        return false;
      }

      final googleSignIn = _googleSignIn ??= GoogleSignIn(
        clientId: kIsWeb ? webClientId : null,
      );
      final gUser = await googleSignIn.signIn();
      if (gUser == null) {
        return false; // user ne Google popup cancel kar diya
      }
      final gAuth = await gUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      final result = await _auth.signInWithCredential(cred);
      // Pehli dafa login hai to Firestore me user document banao
      final doc = await _db.collection('users').doc(result.user!.uid).get();
      if (!doc.exists) {
        final appUser = AppUser(
          uid: result.user!.uid,
          name: result.user!.displayName ?? '',
          email: result.user!.email ?? '',
          photoUrl: result.user!.photoURL ?? '',
          addresses: [],
          fcmTokens: [],
        );
        await _db.collection('users').doc(appUser.uid).set(appUser.toMap());
        _user = appUser;
      } else {
        await _loadUser(result.user!.uid);
      }
      if (expectedRole == 'admin' && !isAdmin) {
        await _googleSignIn?.signOut();
        await _auth.signOut();
        _user = null;
        _error = 'This account does not have admin access. Contact your '
            'project administrator to request the admin role.';
        return false;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _msg(e.code);
      return false;
    } on FirebaseException catch (e) {
      _user = null;
      await _auth.signOut();
      await _googleSignIn?.signOut();
      _error = _firebaseMsg(e);
      return false;
    } catch (e, stackTrace) {
      debugPrint('Google sign-in failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _error = 'Google sign-in failed. Please try again.';
      return false;
    } finally {
      _done();
    }
  }

  // Reset link email par bhejo. null = kamyab, String = error message.
  Future<String?> sendPasswordReset(String email) async {
    _start();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return 'Could not send the reset link: ${e.message ?? _msg(e.code)}';
    } finally {
      _done();
    }
  }

  // Logout (Google session bhi khatam karo)
  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Firebase ke mushkil codes ko simple message me badlo
  String _msg(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account was found for this email address.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'email-already-in-use':
        return 'This email address is already in use.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email and password sign-in is not enabled in Firebase Authentication.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String _firebaseMsg(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore access was denied. Check the security rules for the '
            'users collection.';
      case 'unavailable':
        return 'Firebase is currently unavailable. Check your internet '
            'connection and try again.';
      case 'user-profile-not-found':
        return 'The Firestore profile for this account was not found. For an '
            'admin account, verify the users/{uid} document and role field.';
      default:
        return error.message ??
            'Firebase error (${error.code}). Check the Firebase Console and Firestore rules.';
    }
  }

  // Update the name in Firestore and the current screen.
  Future<void> updateName(String name) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _user == null) return;
    await _db.collection('users').doc(uid).update({'name': name});
    _user = AppUser(
      uid: _user!.uid,
      name: name,
      email: _user!.email,
      photoUrl: _user!.photoUrl,
      role: _user!.role,
      addresses: _user!.addresses,
      fcmTokens: _user!.fcmTokens,
    );
    notifyListeners();
  }

// Profile photo badlo (Cloudinary URL save hota hai)
  Future<void> updatePhoto(String url) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _user == null) return;
    await _db.collection('users').doc(uid).update({'photoUrl': url});
    _user = AppUser(
      uid: _user!.uid,
      name: _user!.name,
      email: _user!.email,
      photoUrl: url,
      role: _user!.role,
      addresses: _user!.addresses,
      fcmTokens: _user!.fcmTokens,
    );
    notifyListeners();
  }
}
