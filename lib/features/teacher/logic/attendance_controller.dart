import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'classes_controller.dart' show AttendanceSettings;

class SessionItem {
  final String id;
  final String date;
  final int sessionNumber;
  final bool teacherVerified;
  final DateTime startTime;
  DateTime? endTime;
  bool isRunning;
  SessionItem({
    required this.id,
    required this.date,
    required this.sessionNumber,
    required this.teacherVerified,
    required this.startTime,
    this.endTime,
    bool? isRunning,
  }) : isRunning = isRunning ?? (endTime == null);
  String get label => 'Session $sessionNumber — $date';
  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String get formattedStartTime =>
      startTime == DateTime(0) ? '—' : _fmt(startTime);
  String get formattedEndTime => endTime == null ? '—' : _fmt(endTime!);
}

class AttendanceRow {
  final String studentUID;
  final String lastName;
  final String firstName;
  final String middleInitial;
  DateTime? timeIn;
  DateTime? timeOut;
  String remark;
  final DateTime sessionStartTime;
  final AttendanceSettings settings;
  AttendanceRow({
    required this.studentUID,
    required this.lastName,
    required this.firstName,
    required this.middleInitial,
    required this.sessionStartTime,
    required this.settings,
    this.timeIn,
    this.timeOut,
    this.remark = '',
  });
  String get displayName {
    final mi = middleInitial.isNotEmpty
        ? ' ${middleInitial[0].toUpperCase()}.'
        : '';
    return '$lastName, $firstName$mi';
  }

  String get status => settings.computeStatus(timeIn, sessionStartTime);
  bool get isAbsent => timeIn == null;
  bool get isLate =>
      !isAbsent &&
      timeIn!.difference(sessionStartTime).inMinutes > settings.onTimeMinutes;
  bool get isOnTime => !isAbsent && !isLate;
}

enum SortColumn { name, timeIn, timeOut, status }

enum SortDirection { asc, desc }

class AttendanceController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String get _teacherUID => _auth.currentUser?.uid ?? '';
  List<ClassItem> _classes = [];
  List<ClassItem> get classes => _classes;
  List<String> _availableDates = [];
  List<String> get availableDates => _availableDates;
  List<SessionItem> _sessions = [];
  List<SessionItem> get sessions => _sessions;
  ClassItem? _selectedClass;
  ClassItem? get selectedClass => _selectedClass;
  String? _selectedDate;
  String? get selectedDate => _selectedDate;
  SessionItem? _selectedSession;
  SessionItem? get selectedSession => _selectedSession;
  List<AttendanceRow> _rows = [];
  List<AttendanceRow> get rows => _sortedRows;
  AttendanceSettings _classSettings = const AttendanceSettings();
  AttendanceSettings get classSettings => _classSettings;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  StreamSubscription? _attendanceSubscription;
  StreamSubscription? _sessionDocSubscription;
  String? _realtimeToast;
  String? get realtimeToast => _realtimeToast;
  void clearRealtimeToast() {
    _realtimeToast = null;
  }

  SortColumn _sortColumn = SortColumn.name;
  SortColumn get sortColumn => _sortColumn;
  SortDirection _sortDirection = SortDirection.asc;
  SortDirection get sortDirection => _sortDirection;
  List<AttendanceRow> get _sortedRows {
    final sorted = List<AttendanceRow>.from(_rows);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case SortColumn.name:
          cmp = a.lastName.compareTo(b.lastName);
          break;
        case SortColumn.timeIn:
          cmp = (a.timeIn ?? DateTime(0)).compareTo(b.timeIn ?? DateTime(0));
          break;
        case SortColumn.timeOut:
          cmp = (a.timeOut ?? DateTime(0)).compareTo(b.timeOut ?? DateTime(0));
          break;
        case SortColumn.status:
          cmp = a.status.compareTo(b.status);
          break;
      }
      return _sortDirection == SortDirection.asc ? cmp : -cmp;
    });
    return sorted;
  }

  void toggleSort(SortColumn column) {
    if (_sortColumn == column) {
      _sortDirection = _sortDirection == SortDirection.asc
          ? SortDirection.desc
          : SortDirection.asc;
    } else {
      _sortColumn = column;
      _sortDirection = SortDirection.asc;
    }
    notifyListeners();
  }

  Future<void> loadClasses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection('classes')
          .where('teacherID', isEqualTo: _teacherUID)
          .get();
      _classes = snap.docs.map((doc) {
        final data = doc.data();
        final settingsMap = data['attendanceSettings'] as Map<String, dynamic>?;
        return ClassItem(
          id: doc.id,
          classCode: data['classCode'] ?? '',
          subjectName: data['subjectName'] ?? '',
          enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
          attendanceSettings: settingsMap != null
              ? AttendanceSettings.fromMap(settingsMap)
              : const AttendanceSettings(),
        );
      }).toList();
      _classes.sort((a, b) => a.classCode.compareTo(b.classCode));
    } catch (e) {
      debugPrint('loadClasses error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectClass(ClassItem cls) async {
    _selectedClass = cls;
    _selectedDate = null;
    _selectedSession = null;
    _sessions = [];
    _availableDates = [];
    _rows = [];
    _classSettings = cls.attendanceSettings;
    _attendanceSubscription?.cancel();
    _sessionDocSubscription?.cancel();
    notifyListeners();
    try {
      final snap = await _db
          .collection('sessions')
          .where('classID', isEqualTo: cls.id)
          .where('teacherVerified', isEqualTo: true)
          .get();
      final dates = snap.docs
          .map((d) => d.data()['date'] as String? ?? '')
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList();
      dates.sort((a, b) => b.compareTo(a));
      _availableDates = dates;
    } catch (e) {
      debugPrint('selectClass error: $e');
    }
    notifyListeners();
    _maybeCleanupForClass(cls.id);
  }

  Future<void> selectDate(String date) async {
    _selectedDate = date;
    _selectedSession = null;
    _sessions = [];
    _rows = [];
    _attendanceSubscription?.cancel();
    _sessionDocSubscription?.cancel();
    notifyListeners();
    if (_selectedClass == null) return;
    try {
      final snap = await _db
          .collection('sessions')
          .where('classID', isEqualTo: _selectedClass!.id)
          .where('date', isEqualTo: date)
          .get();
      final docs = snap.docs.toList();
      docs.sort((a, b) {
        final aTime =
            (a.data()['startTime'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bTime =
            (b.data()['startTime'] as Timestamp?)?.toDate() ?? DateTime(0);
        return aTime.compareTo(bTime);
      });
      _sessions = docs
          .where((doc) => (doc.data()['teacherVerified'] as bool?) == true)
          .toList()
          .asMap()
          .entries
          .map((entry) {
            final data = entry.value.data();
            final startTime =
                (data['startTime'] as Timestamp?)?.toDate() ?? DateTime(0);
            final endTime = (data['endTime'] as Timestamp?)?.toDate();
            return SessionItem(
              id: entry.value.id,
              date: date,
              sessionNumber: entry.key + 1,
              teacherVerified: true,
              startTime: startTime,
              endTime: endTime,
            );
          })
          .toList();
    } catch (e) {
      debugPrint('selectDate error: $e');
    }
    notifyListeners();
  }

  Future<void> selectSession(SessionItem session) async {
    _selectedSession = session;
    _rows = [];
    _attendanceSubscription?.cancel();
    _sessionDocSubscription?.cancel();
    _isLoading = true;
    notifyListeners();
    if (_selectedClass == null) return;
    _sessionDocSubscription = _db
        .collection('sessions')
        .doc(session.id)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || _selectedSession?.id != session.id) return;
          final data = snap.data();
          if (data == null) return;
          final endTime = (data['endTime'] as Timestamp?)?.toDate();
          _selectedSession!.isRunning = endTime == null;
          if (endTime != null) {
            _selectedSession!.endTime = endTime;
          }
          notifyListeners();
        });
    final studentInfoMap = await _fetchStudentInfo(
      _selectedClass!.enrolledStudents,
    );
    final baseRows = _selectedClass!.enrolledStudents.map((uid) {
      final info = studentInfoMap[uid];
      return AttendanceRow(
        studentUID: uid,
        lastName: info?['lastName'] ?? uid,
        firstName: info?['firstName'] ?? '',
        middleInitial: info?['middleName'] ?? '',
        sessionStartTime: session.startTime,
        settings: _classSettings,
      );
    }).toList();
    _isLoading = false;
    _rows = baseRows;
    notifyListeners();
    bool isInitialSnapshot = true;
    _attendanceSubscription = _db
        .collection('sessions')
        .doc(session.id)
        .collection('attendance')
        .snapshots()
        .listen((snap) {
          bool hasNewScan = false;
          String? newScanName;
          for (final change in snap.docChanges) {
            final uid = change.doc.id;
            final rowIndex = _rows.indexWhere((r) => r.studentUID == uid);
            if (rowIndex == -1) continue;
            if (change.type == DocumentChangeType.removed) {
              _rows[rowIndex].timeIn = null;
              _rows[rowIndex].timeOut = null;
              _rows[rowIndex].remark = '';
              continue;
            }
            final data = change.doc.data();
            if (data == null) continue;
            final prevTimeIn = _rows[rowIndex].timeIn;
            _rows[rowIndex].timeIn = (data['timeIn'] as Timestamp?)?.toDate();
            _rows[rowIndex].timeOut = (data['timeOut'] as Timestamp?)?.toDate();
            _rows[rowIndex].remark = data['remark'] ?? '';
            final source = data['source'] as String?;
            final isKioskScan = source == 'kiosk';
            final hasTimeIn = _rows[rowIndex].timeIn != null;
            if (!isInitialSnapshot &&
                isKioskScan &&
                hasTimeIn &&
                (change.type == DocumentChangeType.added ||
                    (change.type == DocumentChangeType.modified &&
                        prevTimeIn == null &&
                        _rows[rowIndex].timeIn != null))) {
              hasNewScan = true;
              newScanName = _rows[rowIndex].displayName;
            }
          }
          isInitialSnapshot = false;
          if (hasNewScan && newScanName != null) {
            _realtimeToast = newScanName;
          }
          notifyListeners();
        });
  }

  Future<Map<String, Map<String, String>>> _fetchStudentInfo(
    List<String> uids,
  ) async {
    final result = <String, Map<String, String>>{};
    if (uids.isEmpty) return result;
    final chunks = <List<String>>[];
    for (var i = 0; i < uids.length; i += 30) {
      chunks.add(uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30));
    }
    for (final chunk in chunks) {
      final snap = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        result[doc.id] = {
          'firstName': data['firstName'] ?? '',
          'lastName': data['lastName'] ?? '',
          'middleName': data['middleName'] ?? '',
        };
      }
    }
    return result;
  }

  Future<String?> forceEndSession() async {
    if (_selectedSession == null) return 'No session selected.';
    if (!(_selectedSession!.isRunning)) return 'Session is already ended.';
    try {
      await _db.collection('sessions').doc(_selectedSession!.id).update({
        'endTime': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      debugPrint('forceEndSession error: $e');
      return 'Failed to end session. Check your connection.';
    }
  }

  Future<String?> deleteSession() async {
    if (_selectedSession == null) return 'No session selected.';
    final deletedSessionId = _selectedSession!.id;
    final dateToRefresh = _selectedDate;
    try {
      final attendanceSnap = await _db
          .collection('sessions')
          .doc(deletedSessionId)
          .collection('attendance')
          .get();
      final docs = attendanceSnap.docs;
      for (var i = 0; i < docs.length; i += 500) {
        final chunk = docs.sublist(i, (i + 500).clamp(0, docs.length));
        final batch = _db.batch();
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      await _db.collection('sessions').doc(deletedSessionId).delete();
      _attendanceSubscription?.cancel();
      _sessionDocSubscription?.cancel();
      _selectedSession = null;
      _rows = [];
      _sessions.removeWhere((s) => s.id == deletedSessionId);
      if (_sessions.isEmpty && dateToRefresh != null) {
        _availableDates.remove(dateToRefresh);
        _selectedDate = null;
      }
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('deleteSession error: $e');
      return 'Failed to delete session. Check your connection.';
    }
  }

  Future<String?> updateAttendance({
    required String studentUID,
    DateTime? timeIn,
    DateTime? timeOut,
    required String remark,
  }) async {
    if (_selectedSession == null) return 'No session selected.';
    if (timeIn == null && timeOut != null) {
      return 'Cannot set Time Out without a Time In.';
    }
    if (timeIn != null && timeOut != null && !timeOut.isAfter(timeIn)) {
      return 'Time Out must be after Time In.';
    }
    try {
      final ref = _db
          .collection('sessions')
          .doc(_selectedSession!.id)
          .collection('attendance')
          .doc(studentUID);
      if (timeIn == null && timeOut == null && remark.trim().isEmpty) {
        await ref.delete();
      } else {
        final computedStatus = _classSettings.computeStatus(
          timeIn,
          _selectedSession!.startTime,
        );
        await ref.set({
          'timeIn': timeIn != null ? Timestamp.fromDate(timeIn) : null,
          'timeOut': timeOut != null ? Timestamp.fromDate(timeOut) : null,
          'status': computedStatus,
          'remark': remark.trim(),
          'source': 'manual',
        });
      }
      return null;
    } catch (e) {
      debugPrint('updateAttendance error: $e');
      return 'Failed to update attendance.';
    }
  }

  List<Map<String, String>> getExportData() {
    return _sortedRows.map((row) {
      return {
        'Name': row.displayName,
        'Time In': row.timeIn != null ? _formatTime(row.timeIn!) : 'N/A',
        'Time Out': row.timeOut != null ? _formatTime(row.timeOut!) : 'N/A',
        'Status': row.status,
        'Remark': row.remark,
      };
    }).toList();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  AttendanceController() {
    loadClasses();
  }
  Future<void> _maybeCleanupForClass(String classId) async {
    try {
      final classDoc = await _db.collection('classes').doc(classId).get();
      if (!classDoc.exists) return;
      final lastCleanUp = (classDoc.data()?['lastCleanUp'] as Timestamp?)
          ?.toDate();
      final now = DateTime.now();
      if (lastCleanUp != null && now.difference(lastCleanUp).inHours < 24) {
        return;
      }
      await _db.collection('classes').doc(classId).update({
        'lastCleanUp': FieldValue.serverTimestamp(),
      });
      await _deleteGhostSessionsForClass(classId);
    } catch (e) {
      debugPrint('_maybeCleanupForClass error: $e');
    }
  }

  Future<void> _deleteGhostSessionsForClass(String classId) async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 12));
      final snap = await _db
          .collection('sessions')
          .where('classID', isEqualTo: classId)
          .where('teacherVerified', isEqualTo: false)
          .where('endTime', isNull: true)
          .get();
      for (final doc in snap.docs) {
        final startTime = (doc.data()['startTime'] as Timestamp?)?.toDate();
        if (startTime != null && startTime.isBefore(cutoff)) {
          await doc.reference.delete();
          debugPrint('Deleted ghost session: ${doc.id}');
        }
      }
    } catch (e) {
      debugPrint('_deleteGhostSessionsForClass error: $e');
    }
  }

  @override
  void dispose() {
    _attendanceSubscription?.cancel();
    _sessionDocSubscription?.cancel();
    super.dispose();
  }
}

class ClassItem {
  final String id;
  final String classCode;
  final String subjectName;
  final List<String> enrolledStudents;
  final AttendanceSettings attendanceSettings;
  ClassItem({
    required this.id,
    required this.classCode,
    required this.subjectName,
    required this.enrolledStudents,
    AttendanceSettings? attendanceSettings,
  }) : attendanceSettings = attendanceSettings ?? const AttendanceSettings();
  String get label => '$classCode — $subjectName';
}
