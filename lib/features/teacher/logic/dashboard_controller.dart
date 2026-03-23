import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _teacherName = '';
  String _teacherEmail = '';
  String get teacherName => _teacherName;
  String get teacherEmail => _teacherEmail;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  Future<void> loadTeacherProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final first = data['firstName'] ?? '';
        final middle = (data['middleName'] as String?) ?? '';
        final last = data['lastName'] ?? '';
        _teacherName = [
          first,
          middle,
          last,
        ].where((s) => s.toString().trim().isNotEmpty).join(' ');
        _teacherEmail = data['email'] ?? user.email ?? '';
      } else {
        _teacherName = user.displayName ?? '';
        _teacherEmail = user.email ?? '';
      }
    } catch (e) {
      debugPrint('loadTeacherProfile error: $e');
      _teacherName = user.displayName ?? '';
      _teacherEmail = user.email ?? '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _auth.signInAnonymously();
    notifyListeners();
  }

  DashboardController() {
    loadTeacherProfile();
  }
}
