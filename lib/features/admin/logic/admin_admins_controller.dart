import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminUserModel {
  final String uid;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String emoji;
  final String role;
  AdminUserModel({
    required this.uid,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.emoji,
    required this.role,
  });
  String get displayName => [
    firstName,
    middleName,
    lastName,
  ].where((s) => s.trim().isNotEmpty).join(' ');
  bool get isSelf => uid == FirebaseAuth.instance.currentUser?.uid;
  factory AdminUserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUserModel(
      uid: doc.id,
      firstName: data['firstName'] ?? '',
      middleName: data['middleName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      emoji: data['emoji'] ?? '🛡️',
      role: data['role'] ?? '',
    );
  }
}

enum AdminsStatus { idle, loading, saving, error, success }

class AdminAdminsController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String get currentUid => _auth.currentUser?.uid ?? '';
  List<AdminUserModel> _admins = [];
  List<AdminUserModel> get admins => _admins;
  bool get isOnlyAdmin =>
      _admins.length == 1 && _admins.first.uid == currentUid;
  List<AdminUserModel> _teacherResults = [];
  List<AdminUserModel> get teacherResults => _teacherResults;
  AdminsStatus _status = AdminsStatus.idle;
  AdminsStatus get status => _status;
  bool get isLoading => _status == AdminsStatus.loading;
  bool get isSaving => _status == AdminsStatus.saving;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  void _setLoading() {
    _status = AdminsStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setSaving() {
    _status = AdminsStatus.saving;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AdminsStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  void _setIdle() {
    _status = AdminsStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AdminsStatus.error) _status = AdminsStatus.idle;
    notifyListeners();
  }

  Future<void> loadAdmins() async {
    _setLoading();
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      _admins = snap.docs.map((d) => AdminUserModel.fromDoc(d)).toList()
        ..sort((a, b) {
          if (a.isSelf) return -1;
          if (b.isSelf) return 1;
          return a.displayName.compareTo(b.displayName);
        });
      _setIdle();
    } catch (e) {
      debugPrint('AdminAdminsController loadAdmins error: $e');
      _setError('Failed to load admin list. Check your connection.');
    }
  }

  Future<void> searchTeachers(String query) async {
    if (query.trim().isEmpty) {
      _teacherResults = [];
      notifyListeners();
      return;
    }
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();
      final q = query.toLowerCase();
      _teacherResults =
          snap.docs
              .map((d) => AdminUserModel.fromDoc(d))
              .where(
                (u) =>
                    u.displayName.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q),
              )
              .toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName));
      notifyListeners();
    } catch (e) {
      debugPrint('searchTeachers error: $e');
      _teacherResults = [];
      notifyListeners();
    }
  }

  void clearTeacherResults() {
    _teacherResults = [];
    notifyListeners();
  }

  Future<String?> promoteToAdmin(String uid) async {
    _setSaving();
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        _setIdle();
        return 'Account not found.';
      }
      final role = doc.data()?['role'];
      if (role != 'teacher') {
        _setIdle();
        return 'Only teacher accounts can be promoted to admin.';
      }
      await _db.collection('users').doc(uid).update({'role': 'admin'});
      await loadAdmins();
      return null;
    } catch (e) {
      debugPrint('promoteToAdmin error: $e');
      _setIdle();
      return 'Failed to promote account. Please try again.';
    }
  }

  Future<String?> removeSelfAdmin() async {
    if (isOnlyAdmin) {
      return 'You are the only admin. Assign another admin first.';
    }
    _setSaving();
    try {
      await _db.collection('users').doc(currentUid).update({'role': 'teacher'});
      _setIdle();
      return null;
    } catch (e) {
      debugPrint('removeSelfAdmin error: $e');
      _setIdle();
      return 'Failed to remove admin role. Please try again.';
    }
  }

  AdminAdminsController() {
    loadAdmins();
  }
}
