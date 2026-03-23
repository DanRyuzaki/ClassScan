import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

enum StudentAuthStatus { idle, loading, success, error }

class StudentAuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StudentAuthStatus _status = StudentAuthStatus.idle;
  StudentAuthStatus get status => _status;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == StudentAuthStatus.loading;
  void _setLoading() {
    _status = StudentAuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = StudentAuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  void _setSuccess() {
    _status = StudentAuthStatus.success;
    notifyListeners();
  }

  void _setIdle() {
    _status = StudentAuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() => _setIdle();
  static const _tokenKey = 'classscan_session_token';
  String _generateToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String? get _localToken => web.window.sessionStorage.getItem(_tokenKey);
  void _saveLocalToken(String token) =>
      web.window.sessionStorage.setItem(_tokenKey, token);
  void _clearLocalToken() => web.window.sessionStorage.removeItem(_tokenKey);
  Future<void> _writeSessionToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({
      'activeSessionToken': token,
    });
  }

  Future<void> _clearSessionToken(String uid) async {
    await _db.collection('users').doc(uid).update({
      'activeSessionToken': FieldValue.delete(),
    });
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
      final shouldProceed = await _syncStudentFirestore(user);
      if (!shouldProceed) {
        await _auth.signInAnonymously();
        return false;
      }
      final doc = await _db.collection('users').doc(user.uid).get();
      final existingToken = doc.data()?['activeSessionToken'] as String?;
      if (existingToken != null && existingToken.isNotEmpty) {
        await _auth.signOut();
        await _auth.signInAnonymously();
        _setError(
          'You are already signed in on another device or browser tab. '
          'Please sign out from the other session first.',
        );
        return false;
      }
      final token = _generateToken();
      await _writeSessionToken(user.uid, token);
      _saveLocalToken(token);
      _setSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('StudentAuth FirebaseAuthException: ${e.code}');
      await _auth.signInAnonymously();
      _setError(_friendlyError(e.code));
      return false;
    } catch (e) {
      debugPrint('StudentAuth unexpected error: $e');
      await _auth.signInAnonymously();
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  Future<bool> _syncStudentFirestore(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (doc.exists) {
      final role = doc.data()?['role'];
      if (role == 'teacher') {
        await _auth.signOut();
        _setError(
          'This account is registered as a teacher. '
          'Please use the Teacher Portal.',
        );
        return false;
      }
      return true;
    }
    final parts = _splitName(user.displayName ?? '');
    await docRef.set({
      'firstName': parts['firstName'],
      'middleName': parts['middleName'],
      'lastName': parts['lastName'],
      'email': user.email ?? '',
      'role': 'student',
      'emoji': '🧑‍🎓',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  Map<String, String> _splitName(String name) {
    final parts = name.trim().split(' ');
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

  Future<bool> isSignedInAsStudent() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return false;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data()?['role'] != 'student') return false;
      final firestoreToken = doc.data()?['activeSessionToken'] as String?;
      final localToken = _localToken;
      if (localToken == null || localToken.isEmpty) {
        if (firestoreToken != null && firestoreToken.isNotEmpty) {
          await _auth.signOut();
          await _auth.signInAnonymously();
          return false;
        }
        await _auth.signOut();
        await _auth.signInAnonymously();
        return false;
      }
      if (firestoreToken != localToken) {
        _clearLocalToken();
        await _auth.signOut();
        await _auth.signInAnonymously();
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await _clearSessionToken(user.uid);
      } catch (e) {
        debugPrint('clearSessionToken error: $e');
      }
    }
    _clearLocalToken();
    await _auth.signOut();
    await _auth.signInAnonymously();
    notifyListeners();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'popup-blocked':
        return 'Popup was blocked. Please allow popups for this site.';
      case 'popup-closed-by-user':
        return 'Sign-in was cancelled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
