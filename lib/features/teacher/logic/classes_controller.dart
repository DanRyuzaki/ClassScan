import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AttendanceSettings {
  final int onTimeMinutes;
  final int scanCooldownSeconds;
  final int timeOutMinimumMinutes;
  final bool locationValidation;
  final int proximityThreshold;
  const AttendanceSettings({
    this.onTimeMinutes = 15,
    this.scanCooldownSeconds = 10,
    this.timeOutMinimumMinutes = 5,
    this.locationValidation = false,
    this.proximityThreshold = 200,
  });
  factory AttendanceSettings.fromMap(Map<String, dynamic> map) {
    return AttendanceSettings(
      onTimeMinutes: (map['onTimeMinutes'] as num?)?.toInt() ?? 15,
      scanCooldownSeconds: (map['scanCooldownSeconds'] as num?)?.toInt() ?? 10,
      timeOutMinimumMinutes:
          (map['timeOutMinimumMinutes'] as num?)?.toInt() ?? 5,
      locationValidation: (map['locationValidation'] as bool?) ?? false,
      proximityThreshold: (map['proximityThreshold'] as num?)?.toInt() ?? 200,
    );
  }
  Map<String, dynamic> toMap() => {
    'onTimeMinutes': onTimeMinutes,
    'scanCooldownSeconds': scanCooldownSeconds,
    'timeOutMinimumMinutes': timeOutMinimumMinutes,
    'locationValidation': locationValidation,
    'proximityThreshold': proximityThreshold,
  };
  String computeStatus(DateTime? timeIn, DateTime sessionStartTime) {
    if (timeIn == null) return 'Absent';
    final minutesLate = timeIn.difference(sessionStartTime).inMinutes;
    if (minutesLate <= onTimeMinutes) return 'Present (On-Time)';
    return 'Present (Late)';
  }
}

class ClassModel {
  final String id;
  final String school;
  final String classCode;
  final String subjectName;
  final String teacherID;
  final List<String> enrolledStudents;
  final List<String> pendingStudents;
  final AttendanceSettings attendanceSettings;
  final List<String> allowedEmailDomains;
  ClassModel({
    required this.id,
    required this.school,
    required this.classCode,
    required this.subjectName,
    required this.teacherID,
    required this.enrolledStudents,
    this.pendingStudents = const [],
    AttendanceSettings? attendanceSettings,
    this.allowedEmailDomains = const [],
  }) : attendanceSettings = attendanceSettings ?? const AttendanceSettings();
  factory ClassModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final settingsMap = data['attendanceSettings'] as Map<String, dynamic>?;
    return ClassModel(
      id: doc.id,
      school: data['school'] ?? '',
      classCode: data['classCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      teacherID: data['teacherID'] ?? '',
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
      pendingStudents: List<String>.from(data['pendingStudents'] ?? []),
      attendanceSettings: settingsMap != null
          ? AttendanceSettings.fromMap(settingsMap)
          : const AttendanceSettings(),
      allowedEmailDomains: List<String>.from(data['allowedEmailDomains'] ?? []),
    );
  }
  Map<String, dynamic> toMap() => {
    'school': school,
    'classCode': classCode,
    'subjectName': subjectName,
    'teacherID': teacherID,
    'enrolledStudents': enrolledStudents,
    'pendingStudents': pendingStudents,
    'attendanceSettings': attendanceSettings.toMap(),
    'allowedEmailDomains': allowedEmailDomains,
  };
  bool isEmailAllowed(String email) {
    if (allowedEmailDomains.isEmpty) return true;
    final lower = email.trim().toLowerCase();
    return allowedEmailDomains.any((domain) => lower.endsWith('@$domain'));
  }
}

class EnrolledStudent {
  final String uid;
  final String fullName;
  final String email;
  EnrolledStudent({
    required this.uid,
    required this.fullName,
    required this.email,
  });
}

class ClassesController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String get _teacherID => _auth.currentUser?.uid ?? '';
  List<ClassModel> _classes = [];
  List<ClassModel> get classes => _filteredClasses;
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  List<ClassModel> get _filteredClasses {
    if (_searchQuery.trim().isEmpty) return _classes;
    final q = _searchQuery.toLowerCase();
    return _classes.where((c) {
      return c.school.toLowerCase().contains(q) ||
          c.subjectName.toLowerCase().contains(q) ||
          c.classCode.toLowerCase().contains(q);
    }).toList();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadClasses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection('classes')
          .where('teacherID', isEqualTo: _teacherID)
          .get();
      _classes = snap.docs.map(ClassModel.fromDoc).toList();
    } catch (e) {
      debugPrint('loadClasses error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? validateClassCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Class code is required.';
    if (value.length > 50) return 'Max 50 characters.';
    final regex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!regex.hasMatch(value)) {
      return 'Only letters, numbers, - and _ allowed.';
    }
    return null;
  }

  String? validateSubjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Subject name is required.';
    }
    if (value.length > 50) return 'Max 250 characters.';
    final regex = RegExp(r'^[a-zA-Z0-9 ]+$');
    if (!regex.hasMatch(value)) return 'Only letters and numbers allowed.';
    return null;
  }

  String? validateSchool(String? value) {
    if (value == null || value.trim().isEmpty) return 'School is required.';
    if (value.length > 100) return 'Max 100 characters.';
    return null;
  }

  static String? validateEmailDomain(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return 'Domain cannot be empty.';
    if (trimmed.contains('@')) return 'Enter the domain only, without "@".';
    final domainRegex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?'
      r'(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*'
      r'\.[a-zA-Z]{2,}$',
    );
    if (!domainRegex.hasMatch(trimmed)) {
      return 'Invalid domain format (e.g. fatima.edu.ph).';
    }
    return null;
  }

  Future<bool> classCodeExists(String code, {String? excludeId}) async {
    final doc = await _db.collection('classes').doc(code.trim()).get();
    if (!doc.exists) return false;
    if (excludeId != null && doc.id == excludeId) return false;
    return true;
  }

  Future<String?> createClass({
    required String school,
    required String classCode,
    required String subjectName,
    List<String> allowedEmailDomains = const [],
  }) async {
    final codeError = validateClassCode(classCode);
    if (codeError != null) return codeError;
    final subjectError = validateSubjectName(subjectName);
    if (subjectError != null) return subjectError;
    final schoolError = validateSchool(school);
    if (schoolError != null) return schoolError;
    final trimmedCode = classCode.trim();
    final exists = await classCodeExists(trimmedCode);
    if (exists) return 'Class code "$trimmedCode" already exists.';
    try {
      await _db.collection('classes').doc(trimmedCode).set({
        'school': school.trim(),
        'classCode': trimmedCode,
        'subjectName': subjectName.trim(),
        'teacherID': _teacherID,
        'enrolledStudents': [],
        'allowedEmailDomains': allowedEmailDomains
            .map((d) => d.trim().toLowerCase())
            .toList(),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('createClass error: $e');
      return 'Failed to create class. Please try again.';
    }
  }

  Future<String?> updateClass({
    required String classId,
    required String school,
    required String classCode,
    required String subjectName,
  }) async {
    final codeError = validateClassCode(classCode);
    if (codeError != null) return codeError;
    final subjectError = validateSubjectName(subjectName);
    if (subjectError != null) return subjectError;
    final schoolError = validateSchool(school);
    if (schoolError != null) return schoolError;
    final trimmedCode = classCode.trim();
    final exists = await classCodeExists(trimmedCode, excludeId: classId);
    if (exists) return 'Class code "$trimmedCode" already exists.';
    try {
      if (classId == trimmedCode) {
        await _db.collection('classes').doc(classId).update({
          'school': school.trim(),
          'subjectName': subjectName.trim(),
        });
      } else {
        final oldDoc = await _db.collection('classes').doc(classId).get();
        final oldData = oldDoc.data() as Map<String, dynamic>;
        await _db.collection('classes').doc(trimmedCode).set({
          'school': school.trim(),
          'classCode': trimmedCode,
          'subjectName': subjectName.trim(),
          'teacherID': oldData['teacherID'],
          'enrolledStudents': oldData['enrolledStudents'] ?? [],
          'pendingStudents': oldData['pendingStudents'] ?? [],
          if (oldData['attendanceSettings'] != null)
            'attendanceSettings': oldData['attendanceSettings'],
          'allowedEmailDomains': oldData['allowedEmailDomains'] ?? [],
        });
        final sessionsSnap = await _db
            .collection('sessions')
            .where('classID', isEqualTo: classId)
            .get();
        if (sessionsSnap.docs.isNotEmpty) {
          final batch = _db.batch();
          for (final doc in sessionsSnap.docs) {
            batch.update(doc.reference, {'classID': trimmedCode});
          }
          await batch.commit();
        }
        await _db.collection('classes').doc(classId).delete();
      }
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('updateClass error: $e');
      return 'Failed to update class. Please try again.';
    }
  }

  Future<String?> deleteClass(String classId) async {
    try {
      await _db.collection('classes').doc(classId).delete();
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('deleteClass error: $e');
      return 'Failed to delete class.';
    }
  }

  Future<String?> addAllowedDomain({
    required String classId,
    required String domain,
  }) async {
    final error = validateEmailDomain(domain);
    if (error != null) return error;
    final normalized = domain.trim().toLowerCase();
    try {
      await _db.collection('classes').doc(classId).update({
        'allowedEmailDomains': FieldValue.arrayUnion([normalized]),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('addAllowedDomain error: $e');
      return 'Failed to add domain. Please try again.';
    }
  }

  Future<int> countStudentsWithDomain({
    required String classId,
    required String domain,
  }) async {
    try {
      final classDoc = await _db.collection('classes').doc(classId).get();
      if (!classDoc.exists) return 0;
      final enrolledUIDs = List<String>.from(
        classDoc.data()?['enrolledStudents'] ?? [],
      );
      if (enrolledUIDs.isEmpty) return 0;
      int count = 0;
      final suffix = '@${domain.trim().toLowerCase()}';
      for (var i = 0; i < enrolledUIDs.length; i += 30) {
        final chunk = enrolledUIDs.sublist(
          i,
          (i + 30).clamp(0, enrolledUIDs.length),
        );
        final snap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          final email = (doc.data()['email'] as String? ?? '')
              .trim()
              .toLowerCase();
          if (email.endsWith(suffix)) count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('countStudentsWithDomain error: $e');
      return 0;
    }
  }

  Future<String?> removeAllowedDomain({
    required String classId,
    required String domain,
  }) async {
    final normalized = domain.trim().toLowerCase();
    try {
      await _db.collection('classes').doc(classId).update({
        'allowedEmailDomains': FieldValue.arrayRemove([normalized]),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('removeAllowedDomain error: $e');
      return 'Failed to remove domain. Please try again.';
    }
  }

  Future<String?> enrollStudentByEmail({
    required String classId,
    required String email,
  }) async {
    if (email.trim().isEmpty) return 'Please enter an email address.';
    try {
      final snap = await _db
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        return 'No account found with email "$email".';
      }
      final studentDoc = snap.docs.first;
      final data = studentDoc.data();
      if (data['role'] != 'student') {
        return 'This account is not registered as a student.';
      }
      final classDoc = await _db.collection('classes').doc(classId).get();
      if (!classDoc.exists) return 'Class not found.';
      final classData = classDoc.data()!;
      final allowedDomains = List<String>.from(
        classData['allowedEmailDomains'] ?? [],
      );
      if (allowedDomains.isNotEmpty) {
        final emailLower = email.trim().toLowerCase();
        final domainAllowed = allowedDomains.any(
          (d) => emailLower.endsWith('@$d'),
        );
        if (!domainAllowed) {
          final domainList = allowedDomains.join(', ');
          return 'This class only allows email addresses from: $domainList. '
              '"$email" does not match any allowed domain.';
        }
      }
      final enrolled = List<String>.from(classData['enrolledStudents'] ?? []);
      final pending = List<String>.from(classData['pendingStudents'] ?? []);
      final studentUID = studentDoc.id;
      if (enrolled.contains(studentUID)) {
        return 'This student is already enrolled in this class.';
      }
      if (pending.contains(studentUID)) {
        return 'This student already has a pending request to join this class.';
      }
      await _db.collection('classes').doc(classId).update({
        'enrolledStudents': FieldValue.arrayUnion([studentUID]),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('enrollStudentByEmail error: $e');
      return 'Failed to enroll student. Please try again.';
    }
  }

  Future<String?> removeStudent({
    required String classId,
    required String studentUID,
  }) async {
    try {
      await _db.collection('classes').doc(classId).update({
        'enrolledStudents': FieldValue.arrayRemove([studentUID]),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('removeStudent error: $e');
      return 'Failed to remove student.';
    }
  }

  Future<String?> removeStudents({
    required String classId,
    required List<String> studentUIDs,
  }) async {
    if (studentUIDs.isEmpty) return null;
    try {
      await _db.collection('classes').doc(classId).update({
        'enrolledStudents': FieldValue.arrayRemove(studentUIDs),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('removeStudents error: $e');
      return 'Failed to remove students. Please try again.';
    }
  }

  Future<ClassModel?> fetchClassDoc(String classId) async {
    try {
      final doc = await _db.collection('classes').doc(classId).get();
      if (!doc.exists) return null;
      return ClassModel.fromDoc(doc);
    } catch (e) {
      debugPrint('fetchClassDoc error: $e');
      return null;
    }
  }

  Future<List<EnrolledStudent>> fetchEnrolledStudents(List<String> uids) async {
    if (uids.isEmpty) return [];
    try {
      final chunks = <List<String>>[];
      for (var i = 0; i < uids.length; i += 30) {
        chunks.add(
          uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30),
        );
      }
      final students = <EnrolledStudent>[];
      for (final chunk in chunks) {
        final snap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          final first = data['firstName'] ?? '';
          final middle = (data['middleName'] as String?) ?? '';
          final last = data['lastName'] ?? '';
          final fullName = [
            first,
            middle,
            last,
          ].where((s) => s.toString().trim().isNotEmpty).join(' ');
          students.add(
            EnrolledStudent(
              uid: doc.id,
              fullName: fullName,
              email: data['email'] ?? '',
            ),
          );
        }
      }
      return students;
    } catch (e) {
      debugPrint('fetchEnrolledStudents error: $e');
      return [];
    }
  }

  Future<String?> approvePendingStudent({
    required String classId,
    required String studentUID,
  }) async {
    try {
      await _db.collection('classes').doc(classId).update({
        'pendingStudents': FieldValue.arrayRemove([studentUID]),
        'enrolledStudents': FieldValue.arrayUnion([studentUID]),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('approvePendingStudent error: $e');
      return 'Failed to approve student.';
    }
  }

  Future<String?> declinePendingStudent({
    required String classId,
    required String studentUID,
  }) async {
    try {
      await _db.collection('classes').doc(classId).update({
        'pendingStudents': FieldValue.arrayRemove([studentUID]),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('declinePendingStudent error: $e');
      return 'Failed to decline student.';
    }
  }

  Future<String?> saveAttendanceSettings({
    required String classId,
    required int onTimeMinutes,
    required int scanCooldownSeconds,
    required int timeOutMinimumMinutes,
    required bool locationValidation,
    required int proximityThreshold,
  }) async {
    if (onTimeMinutes < 0) return 'On-time minutes cannot be negative.';
    if (scanCooldownSeconds < 1) {
      return 'Scan cooldown must be at least 1 second.';
    }
    if (timeOutMinimumMinutes < 1) {
      return 'Time-out minimum must be at least 1 minute.';
    }
    if (proximityThreshold < 10) {
      return 'Proximity threshold must be at least 10 meters.';
    }
    try {
      await _db.collection('classes').doc(classId).update({
        'attendanceSettings': AttendanceSettings(
          onTimeMinutes: onTimeMinutes,
          scanCooldownSeconds: scanCooldownSeconds,
          timeOutMinimumMinutes: timeOutMinimumMinutes,
          locationValidation: locationValidation,
          proximityThreshold: proximityThreshold,
        ).toMap(),
      });
      await loadClasses();
      return null;
    } catch (e) {
      debugPrint('saveAttendanceSettings error: $e');
      return 'Failed to save settings. Please try again.';
    }
  }

  ClassesController() {
    loadClasses();
  }
}
