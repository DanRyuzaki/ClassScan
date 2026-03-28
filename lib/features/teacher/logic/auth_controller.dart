import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum AuthStatus { idle, loading, success, error }

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  AuthStatus _status = AuthStatus.idle;
  AuthStatus get status => _status;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? _successMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _status == AuthStatus.loading;
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _setSuccess([String? message]) {
    _status = AuthStatus.success;
    _successMessage = message;
    notifyListeners();
  }

  void _setIdle() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        await _auth.signOut();
      }
      final provider = GoogleAuthProvider();
      final result = await _auth.signInWithPopup(provider);
      final user = result.user;
      if (user == null) {
        _setError('Sign-in failed. Please try again.');
        await _auth.signInAnonymously();
        return false;
      }
      final shouldProceed = await _syncTeacherFirestore(user);
      if (!shouldProceed) {
        await _auth.signInAnonymously();
        return false;
      }
      _setSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} — ${e.message}');
      await _auth.signInAnonymously();
      _setError(_friendlyAuthError(e.code));
      return false;
    } catch (e) {
      debugPrint('signInWithGoogle unexpected error: $e');
      await _auth.signInAnonymously();
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  Future<bool> _syncTeacherFirestore(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (doc.exists) {
      final role = doc.data()?['role'];
      if (role == 'student') {
        await _auth.signOut();
        _setError('This account is registered as a student, not a teacher.');
        return false;
      }
      if (role == 'teacher' || role == 'admin') {
        final err = _checkBan(doc.data()!);
        if (err != null) {
          await _auth.signOut();
          _setError(err);
          return false;
        }
        return true;
      }
      await _auth.signOut();
      _setError('Unrecognized account role. Please contact an administrator.');
      return false;
    }
    final nameParts = _splitDisplayName(user.displayName ?? '');
    final qrToken = _generateQrToken();
    await docRef.set({
      'firstName': nameParts['firstName'],
      'middleName': nameParts['middleName'],
      'lastName': nameParts['lastName'],
      'email': user.email ?? '',
      'role': 'teacher',
      'qrToken': qrToken,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  String? _checkBan(Map<String, dynamic> data) {
    final isBanned = data['isBanned'] as bool? ?? false;
    if (!isBanned) return null;
    final bannedUntilTs = data['bannedUntil'] as Timestamp?;
    if (bannedUntilTs != null &&
        DateTime.now().isAfter(bannedUntilTs.toDate())) {
      return null;
    }
    final reason = (data['banReason'] as String?)?.trim() ?? 'No reason given.';
    final days = bannedUntilTs == null
        ? 0
        : bannedUntilTs.toDate().difference(DateTime.now()).inDays + 1;
    final dayLabel = days == 1 ? 'day' : 'days';
    return 'Your account has been temporarily suspended for $days $dayLabel.\n'
        'Reason: $reason';
  }

  String _generateQrToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(32, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Map<String, String> _splitDisplayName(String displayName) {
    final parts = displayName.trim().split(' ');
    if (parts.length == 1) {
      return {'firstName': parts[0], 'middleName': '', 'lastName': ''};
    } else if (parts.length == 2) {
      return {'firstName': parts[0], 'middleName': '', 'lastName': parts[1]};
    } else {
      return {
        'firstName': parts[0],
        'middleName': parts.sublist(1, parts.length - 1).join(' '),
        'lastName': parts.last,
      };
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<bool> isSignedInAsTeacher() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return false;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.exists && doc.data()?['role'] == 'teacher';
    } catch (_) {
      return false;
    }
  }

  Future<bool> isSignedInAsAdmin() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return false;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.exists && doc.data()?['role'] == 'admin';
    } catch (_) {
      return false;
    }
  }

  Future<String?> getSignedInRole() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return doc.data()?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'popup-blocked':
        return 'Popup was blocked. Please allow popups for this site.';
      case 'popup-closed-by-user':
        return 'Sign-in was cancelled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email '
            'using a different sign-in method.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  void clearMessages() => _setIdle();
}
