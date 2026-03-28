import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminClassModel {
  final String id;
  final String school;
  final String classCode;
  final String subjectName;
  final String teacherID;
  final int enrolledCount;
  final int pendingCount;
  bool hasActiveSession;
  String? lastSessionDate;
  String teacherName;
  AdminClassModel({
    required this.id,
    required this.school,
    required this.classCode,
    required this.subjectName,
    required this.teacherID,
    required this.enrolledCount,
    required this.pendingCount,
    this.hasActiveSession = false,
    this.lastSessionDate,
    this.teacherName = '',
  });
  factory AdminClassModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminClassModel(
      id: doc.id,
      school: data['school'] ?? '',
      classCode: data['classCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      teacherID: data['teacherID'] ?? '',
      enrolledCount: (data['enrolledStudents'] as List? ?? []).length,
      pendingCount: (data['pendingStudents'] as List? ?? []).length,
    );
  }
}

class AdminClassesController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<AdminClassModel> _classes = [];
  List<AdminClassModel> get classes => _classes;
  String _search = '';
  List<AdminClassModel> get filtered {
    if (_search.trim().isEmpty) return _classes;
    final q = _search.toLowerCase();
    return _classes
        .where(
          (c) =>
              c.subjectName.toLowerCase().contains(q) ||
              c.classCode.toLowerCase().contains(q) ||
              c.teacherName.toLowerCase().contains(q) ||
              c.school.toLowerCase().contains(q),
        )
        .toList();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  final Map<String, StreamSubscription> _sessionListeners = {};
  void updateSearch(String value) {
    _search = value;
    notifyListeners();
  }

  Future<void> loadClasses() async {
    _isLoading = true;
    notifyListeners();
    _cancelAllListeners();
    try {
      final classSnap = await _db.collection('classes').get();
      _classes = classSnap.docs.map((d) => AdminClassModel.fromDoc(d)).toList()
        ..sort((a, b) => a.subjectName.compareTo(b.subjectName));
      await Future.wait(_classes.map((cls) => _enrichClass(cls)));
      for (final cls in _classes) {
        _watchSession(cls);
      }
    } catch (e) {
      debugPrint('AdminClassesController loadClasses error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _enrichClass(AdminClassModel cls) async {
    try {
      final userDoc = await _db.collection('users').doc(cls.teacherID).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final first = data['firstName'] ?? '';
        final middle = (data['middleName'] as String?) ?? '';
        final last = data['lastName'] ?? '';
        cls.teacherName = [
          first,
          middle,
          last,
        ].where((s) => s.trim().isNotEmpty).join(' ');
      }
    } catch (_) {}
    try {
      final sessionSnap = await _db
          .collection('sessions')
          .where('classID', isEqualTo: cls.id)
          .where('teacherVerified', isEqualTo: true)
          .get();
      if (sessionSnap.docs.isNotEmpty) {
        final dates =
            sessionSnap.docs
                .map((d) => d.data()['date'] as String? ?? '')
                .where((d) => d.isNotEmpty)
                .toList()
              ..sort((a, b) => b.compareTo(a));
        cls.lastSessionDate = dates.isNotEmpty ? dates.first : null;
      }
    } catch (_) {}
  }

  String get _todayDateString {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void _watchSession(AdminClassModel cls) {
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
          _classes[index].hasActiveSession = snap.docs.any((doc) {
            final sessionDate = doc.data()['date'] as String? ?? '';
            return sessionDate == today;
          });
          notifyListeners();
        });
  }

  void _cancelAllListeners() {
    for (final sub in _sessionListeners.values) {
      sub.cancel();
    }
    _sessionListeners.clear();
  }

  Future<String?> deleteClass(String classId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final sessionSnap = await _db
          .collection('sessions')
          .where('classID', isEqualTo: classId)
          .get();
      for (final sessionDoc in sessionSnap.docs) {
        await _deleteSubCollection(sessionDoc.reference, 'attendance');
        await sessionDoc.reference.delete();
      }
      await _db.collection('classes').doc(classId).delete();
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('AdminClassesController deleteClass error: $e');
      _isLoading = false;
      notifyListeners();
      return 'Failed to delete class. Please try again.';
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

  AdminClassesController() {
    loadClasses();
  }
  @override
  void dispose() {
    _cancelAllListeners();
    super.dispose();
  }
}
