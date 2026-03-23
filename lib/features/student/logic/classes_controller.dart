import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentClassModel {
  final String id;
  final String school;
  final String classCode;
  final String subjectName;
  final String teacherID;
  final bool isPending;
  bool hasActiveSession;
  StudentClassModel({
    required this.id,
    required this.school,
    required this.classCode,
    required this.subjectName,
    required this.teacherID,
    required this.isPending,
    this.hasActiveSession = false,
  });
  factory StudentClassModel.fromDoc(
    DocumentSnapshot doc, {
    required bool isPending,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentClassModel(
      id: doc.id,
      school: data['school'] ?? '',
      classCode: data['classCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      teacherID: data['teacherID'] ?? '',
      isPending: isPending,
    );
  }
}

class StudentClassesController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String get _uid => _auth.currentUser?.uid ?? '';
  List<StudentClassModel> _classes = [];
  List<StudentClassModel> get classes => _classes;
  List<StudentClassModel> get enrolledClasses =>
      _classes.where((c) => !c.isPending).toList();
  List<StudentClassModel> get pendingClasses =>
      _classes.where((c) => c.isPending).toList();
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  final Map<String, StreamSubscription> _sessionListeners = {};
  Future<void> loadClasses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final enrolledSnap = await _db
          .collection('classes')
          .where('enrolledStudents', arrayContains: _uid)
          .get();
      final pendingSnap = await _db
          .collection('classes')
          .where('pendingStudents', arrayContains: _uid)
          .get();
      final enrolled = enrolledSnap.docs
          .map((d) => StudentClassModel.fromDoc(d, isPending: false))
          .toList();
      final pending = pendingSnap.docs
          .map((d) => StudentClassModel.fromDoc(d, isPending: true))
          .toList();
      _classes = [...enrolled, ...pending];
      _classes.sort((a, b) => a.subjectName.compareTo(b.subjectName));
      _cancelAllListeners();
      for (final cls in enrolled) {
        _watchSession(cls);
      }
    } catch (e) {
      debugPrint('StudentClasses loadClasses error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String get _todayDateString {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void _watchSession(StudentClassModel cls) {
    _sessionListeners[cls.id]?.cancel();
    _sessionListeners[cls.id] = _db
        .collection('sessions')
        .where('classID', isEqualTo: cls.id)
        .where('teacherVerified', isEqualTo: true)
        .where('endTime', isNull: true)
        .snapshots()
        .listen((snap) {
          final index = _classes.indexWhere((c) => c.id == cls.id);
          if (index == -1) return;
          final today = _todayDateString;
          final hasActiveTodaySession = snap.docs.any((doc) {
            final sessionDate = doc.data()['date'] as String? ?? '';
            return sessionDate == today;
          });
          _classes[index].hasActiveSession = hasActiveTodaySession;
          notifyListeners();
        });
  }

  void _cancelAllListeners() {
    for (final sub in _sessionListeners.values) {
      sub.cancel();
    }
    _sessionListeners.clear();
  }

  Future<String?> joinClass(String classCode) async {
    if (classCode.trim().isEmpty) return 'Please enter a class code.';
    try {
      final doc = await _db.collection('classes').doc(classCode.trim()).get();
      if (!doc.exists) {
        return 'No class found with code "$classCode".';
      }
      final data = doc.data()!;
      final enrolled = List<String>.from(data['enrolledStudents'] ?? []);
      final pending = List<String>.from(data['pendingStudents'] ?? []);
      if (enrolled.contains(_uid)) {
        return 'You are already enrolled in this class.';
      }
      if (pending.contains(_uid)) {
        return 'Your request to join this class is already pending.';
      }
      await _db.collection('classes').doc(classCode.trim()).update({
        'pendingStudents': FieldValue.arrayUnion([_uid]),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('joinClass error: $e');
      return 'Failed to join class. Please try again.';
    }
  }

  Future<String?> unenrollFromClass(String classId) async {
    try {
      await _db.collection('classes').doc(classId).update({
        'enrolledStudents': FieldValue.arrayRemove([_uid]),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('unenrollFromClass error: $e');
      return 'Failed to unenroll. Please try again.';
    }
  }

  Future<String?> cancelPendingRequest(String classId) async {
    try {
      await _db.collection('classes').doc(classId).update({
        'pendingStudents': FieldValue.arrayRemove([_uid]),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('cancelPendingRequest error: $e');
      return 'Failed to cancel request. Please try again.';
    }
  }

  StudentClassesController() {
    loadClasses();
  }
  @override
  void dispose() {
    _cancelAllListeners();
    super.dispose();
  }
}
