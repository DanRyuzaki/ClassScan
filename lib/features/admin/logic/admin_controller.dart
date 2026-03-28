import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum AdminStatus { idle, loading, success, error }

class AdminController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _firstName = '';
  String _middleName = '';
  String _lastName = '';
  String _email = '';
  String _emoji = '🛡️';
  String get firstName => _firstName;
  String get middleName => _middleName;
  String get lastName => _lastName;
  String get email => _email;
  String get emoji => _emoji;
  String get uid => _auth.currentUser?.uid ?? '';
  String get displayName => [
    _firstName,
    _middleName,
    _lastName,
  ].where((s) => s.trim().isNotEmpty).join(' ');
  AdminStatus _status = AdminStatus.idle;
  AdminStatus get status => _status;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? _successMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _status == AdminStatus.loading;
  void _setLoading() {
    _status = AdminStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AdminStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  void _setSuccess(String msg) {
    _status = AdminStatus.success;
    _successMessage = msg;
    notifyListeners();
  }

  void clearStatus() {
    _status = AdminStatus.idle;
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
        _emoji = data['emoji'] ?? '🛡️';
      } else {
        _email = user.email ?? '';
        _firstName = user.displayName ?? '';
      }
      _status = AdminStatus.idle;
      notifyListeners();
    } catch (e) {
      debugPrint('AdminController loadProfile error: $e');
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
      debugPrint('AdminController saveProfile error: $e');
      _setError('Failed to save profile. Please try again.');
    }
  }

  Future<String?> removeSelfAdmin() async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      final otherAdmins = snap.docs.where((d) => d.id != uid).toList();
      if (otherAdmins.isEmpty) {
        return 'You are the only admin. Assign another admin first before '
            'removing yourself.';
      }
      await _db.collection('users').doc(uid).update({'role': 'teacher'});
      return null;
    } catch (e) {
      debugPrint('AdminController removeSelfAdmin error: $e');
      return 'Failed to remove admin role. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _auth.signInAnonymously();
    notifyListeners();
  }

  AdminController() {
    loadProfile();
  }
}
