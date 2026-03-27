import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum SettingsStatus { idle, loading, success, error }

class SettingsController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _firstName = '';
  String _middleName = '';
  String _lastName = '';
  String _email = '';
  String _role = '';
  String _emoji = '🧑‍🏫';
  String get firstName => _firstName;
  String get middleName => _middleName;
  String get lastName => _lastName;
  String get email => _email;
  String get role => _role;
  String get emoji => _emoji;
  String get uid => _auth.currentUser?.uid ?? '';
  String get displayName {
    return [
      _firstName,
      _middleName,
      _lastName,
    ].where((s) => s.trim().isNotEmpty).join(' ');
  }

  String _qrToken = '';
  String get qrToken => _qrToken;
  bool get hasQrToken => _qrToken.isNotEmpty;
  String get qrPayload => hasQrToken ? 'CLASSSCAN|$uid|$_qrToken' : '';
  bool _qrVisible = false;
  bool get qrVisible => _qrVisible;
  bool _regenerating = false;
  bool get regenerating => _regenerating;
  void toggleQrVisibility() {
    _qrVisible = !_qrVisible;
    notifyListeners();
  }

  String _generateQrToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(32, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String?> regenerateQrToken() async {
    _regenerating = true;
    notifyListeners();
    try {
      final newToken = _generateQrToken();
      await _db.collection('users').doc(uid).update({'qrToken': newToken});
      _qrToken = newToken;
      _regenerating = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('regenerateQrToken error: $e');
      _regenerating = false;
      notifyListeners();
      return 'Failed to regenerate QR. Check your connection.';
    }
  }

  SettingsStatus _status = SettingsStatus.idle;
  SettingsStatus get status => _status;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? _successMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _status == SettingsStatus.loading;
  void _setLoading() {
    _status = SettingsStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = SettingsStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  void _setSuccess(String msg) {
    _status = SettingsStatus.success;
    _successMessage = msg;
    notifyListeners();
  }

  void clearStatus() {
    _status = SettingsStatus.idle;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _setLoading();
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _firstName = data['firstName'] ?? '';
        _middleName = data['middleName'] ?? '';
        _lastName = data['lastName'] ?? '';
        _email = data['email'] ?? user.email ?? '';
        _role = data['role'] ?? 'teacher';
        _emoji = data['emoji'] ?? '🧑‍🏫';
        final storedToken = data['qrToken'] as String?;
        if (storedToken != null && storedToken.isNotEmpty) {
          _qrToken = storedToken;
        } else {
          final generated = _generateQrToken();
          await _db.collection('users').doc(user.uid).update({
            'qrToken': generated,
          });
          _qrToken = generated;
        }
      } else {
        _email = user.email ?? '';
        _firstName = user.displayName ?? '';
      }
      _status = SettingsStatus.idle;
      notifyListeners();
    } catch (e) {
      debugPrint('loadProfile error: $e');
      _setError('Failed to load profile.');
    }
  }

  Future<void> saveProfile({
    required String firstName,
    required String middleName,
    required String lastName,
    required String emoji,
  }) async {
    if (firstName.trim().isEmpty) {
      _setError('First name cannot be empty.');
      return;
    }
    if (lastName.trim().isEmpty) {
      _setError('Last name cannot be empty.');
      return;
    }
    _setLoading();
    try {
      await _db.collection('users').doc(uid).update({
        'firstName': firstName.trim(),
        'middleName': middleName.trim(),
        'lastName': lastName.trim(),
        'emoji': emoji,
      });
      _firstName = firstName.trim();
      _middleName = middleName.trim();
      _lastName = lastName.trim();
      _emoji = emoji;
      _setSuccess('Profile updated successfully.');
    } catch (e) {
      debugPrint('saveProfile error: $e');
      _setError('Failed to save profile. Please try again.');
    }
  }

  SettingsController() {
    loadProfile();
  }
}
