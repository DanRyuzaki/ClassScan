import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAccountModel {
  final String uid;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String emoji;
  final String role;
  final bool isBanned;
  final DateTime? bannedUntil;
  final String? banReason;
  final DateTime? lastSession;
  AdminAccountModel({
    required this.uid,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.emoji,
    required this.role,
    required this.isBanned,
    this.bannedUntil,
    this.banReason,
    this.lastSession,
  });
  String get displayName => [
    firstName,
    middleName,
    lastName,
  ].where((s) => s.trim().isNotEmpty).join(' ');
  bool get isCurrentlyBanned {
    if (!isBanned) return false;
    if (bannedUntil == null) return true;
    return DateTime.now().isBefore(bannedUntil!);
  }

  int get daysRemainingBan {
    if (bannedUntil == null) return 0;
    final remaining = bannedUntil!.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining + 1;
  }

  String get lastSessionLabel {
    if (lastSession == null) return 'Never';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(
      lastSession!.year,
      lastSession!.month,
      lastSession!.day,
    );
    final diff = today.difference(sessionDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }

  factory AdminAccountModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bannedUntilTs = data['bannedUntil'] as Timestamp?;
    final lastSessionTs = data['lastSession'] as Timestamp?;
    return AdminAccountModel(
      uid: doc.id,
      firstName: data['firstName'] ?? '',
      middleName: data['middleName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      emoji: data['emoji'] ?? '🧑',
      role: data['role'] ?? '',
      isBanned: data['isBanned'] ?? false,
      bannedUntil: bannedUntilTs?.toDate(),
      banReason: data['banReason'] as String?,
      lastSession: lastSessionTs?.toDate(),
    );
  }
}

enum AdminAccountsStatus { idle, loading, saving, error, success }

class AdminAccountsController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String role;
  AdminAccountsController({required this.role}) {
    loadAccounts();
  }
  List<AdminAccountModel> _accounts = [];
  List<AdminAccountModel> get accounts => _accounts;
  String _search = '';
  String get search => _search;
  List<AdminAccountModel> get filtered {
    if (_search.trim().isEmpty) return _accounts;
    final q = _search.toLowerCase();
    return _accounts.where((a) {
      return a.displayName.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q);
    }).toList();
  }

  AdminAccountsStatus _status = AdminAccountsStatus.idle;
  AdminAccountsStatus get status => _status;
  bool get isLoading => _status == AdminAccountsStatus.loading;
  bool get isSaving => _status == AdminAccountsStatus.saving;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? _successMessage;
  String? get successMessage => _successMessage;
  void updateSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void _setLoading() {
    _status = AdminAccountsStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setSaving() {
    _status = AdminAccountsStatus.saving;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AdminAccountsStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  void _setSuccess(String msg) {
    _status = AdminAccountsStatus.success;
    _successMessage = msg;
    _errorMessage = null;
    notifyListeners();
  }

  void clearStatus() {
    _status = AdminAccountsStatus.idle;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadAccounts() async {
    _setLoading();
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      _accounts = snap.docs.map((d) => AdminAccountModel.fromDoc(d)).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      _status = AdminAccountsStatus.idle;
      notifyListeners();
    } catch (e) {
      debugPrint('AdminAccountsController loadAccounts error: $e');
      _setError('Failed to load accounts. Check your connection.');
    }
  }

  Future<String?> createAccount({
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
  }) async {
    if (firstName.trim().isEmpty) return 'First name is required.';
    if (lastName.trim().isEmpty) return 'Last name is required.';
    if (email.trim().isEmpty) return 'Email is required.';
    _setSaving();
    try {
      final existing = await _db
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        _setError('An account with this email already exists.');
        return 'An account with this email already exists.';
      }
      await _db.collection('users').add({
        'firstName': firstName.trim(),
        'middleName': middleName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim().toLowerCase(),
        'role': role,
        'emoji': role == 'teacher' ? '🧑‍🏫' : '🧑‍🎓',
        'isBanned': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdByAdmin': true,
      });
      await loadAccounts();
      _setSuccess('Account created successfully.');
      return null;
    } catch (e) {
      debugPrint('createAccount error: $e');
      _setError('Failed to create account. Please try again.');
      return 'Failed to create account. Please try again.';
    }
  }

  Future<int> getTeacherClassCount(String uid) async {
    if (role != 'teacher') return 0;
    try {
      final snap = await _db
          .collection('classes')
          .where('teacherID', isEqualTo: uid)
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<String?> deleteAccount(String uid) async {
    _setSaving();
    try {
      if (role == 'student') {
        await _deleteStudentData(uid);
      } else if (role == 'teacher') {
        await _deleteTeacherData(uid);
      }
      await _db.collection('users').doc(uid).delete();
      await loadAccounts();
      _setSuccess('Account deleted.');
      return null;
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      _setError('Failed to delete account.');
      return 'Failed to delete account.';
    }
  }

  Future<void> _deleteStudentData(String uid) async {
    final enrolledSnap = await _db
        .collection('classes')
        .where('enrolledStudents', arrayContains: uid)
        .get();
    final pendingSnap = await _db
        .collection('classes')
        .where('pendingStudents', arrayContains: uid)
        .get();
    final Map<String, DocumentSnapshot> affected = {};
    for (final doc in [...enrolledSnap.docs, ...pendingSnap.docs]) {
      affected[doc.id] = doc;
    }
    if (affected.isEmpty) return;
    final batch = _db.batch();
    for (final doc in affected.values) {
      batch.update(doc.reference, {
        'enrolledStudents': FieldValue.arrayRemove([uid]),
        'pendingStudents': FieldValue.arrayRemove([uid]),
      });
    }
    await batch.commit();
  }

  Future<void> _deleteTeacherData(String uid) async {
    final sessionSnap = await _db
        .collection('sessions')
        .where('teacherID', isEqualTo: uid)
        .get();
    for (final sessionDoc in sessionSnap.docs) {
      await _deleteSubCollection(sessionDoc.reference, 'attendance');
      await sessionDoc.reference.delete();
    }
    final classSnap = await _db
        .collection('classes')
        .where('teacherID', isEqualTo: uid)
        .get();
    if (classSnap.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final doc in classSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteSubCollection(
    DocumentReference parentRef,
    String subCollectionName,
  ) async {
    const chunkSize = 400;
    QuerySnapshot snap;
    do {
      snap = await parentRef
          .collection(subCollectionName)
          .limit(chunkSize)
          .get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snap.docs.length == chunkSize);
  }

  Future<String?> banAccount({
    required String uid,
    required int days,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) return 'A ban reason is required.';
    if (days < 1) return 'Ban must be at least 1 day.';
    _setSaving();
    try {
      final bannedUntil = DateTime.now().add(Duration(days: days));
      await _db.collection('users').doc(uid).update({
        'isBanned': true,
        'bannedUntil': Timestamp.fromDate(bannedUntil),
        'banReason': reason.trim(),
      });
      await loadAccounts();
      _setSuccess('Account banned for $days day${days == 1 ? '' : 's'}.');
      return null;
    } catch (e) {
      debugPrint('banAccount error: $e');
      _setError('Failed to ban account.');
      return 'Failed to ban account.';
    }
  }

  Future<String?> unbanAccount(String uid) async {
    _setSaving();
    try {
      await _db.collection('users').doc(uid).update({
        'isBanned': false,
        'bannedUntil': FieldValue.delete(),
        'banReason': FieldValue.delete(),
      });
      await loadAccounts();
      _setSuccess('Account unbanned.');
      return null;
    } catch (e) {
      debugPrint('unbanAccount error: $e');
      _setError('Failed to unban account.');
      return 'Failed to unban account.';
    }
  }
}
