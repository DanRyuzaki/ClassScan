import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum SessionStatus { notStarted, running, ended }

class KioskToast {
  final String title;
  final String message;
  final bool isError;
  KioskToast({
    required this.title,
    required this.message,
    this.isError = false,
  });
}

class KioskUser {
  final String uid;
  final String fullName;
  final String role;
  KioskUser({required this.uid, required this.fullName, required this.role});
  static KioskUser fromDoc(String uid, Map<String, dynamic> data) {
    final first = data['firstName'] ?? '';
    final middle = (data['middleName'] as String?) ?? '';
    final last = data['lastName'] ?? '';
    final fullName = [
      first,
      middle,
      last,
    ].where((s) => s.toString().trim().isNotEmpty).join(' ');
    return KioskUser(uid: uid, fullName: fullName, role: data['role'] ?? '');
  }
}

class KioskController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late DateTime _now;
  Timer? _clockTimer;
  DateTime get localNow => DateTime.now();
  String get timezoneLabel {
    final offset = DateTime.now().timeZoneOffset;
    final h = offset.inHours;
    final m = offset.inMinutes.abs() % 60;
    final sign = h >= 0 ? '+' : '-';
    return m == 0
        ? 'GMT$sign${h.abs()}'
        : 'GMT$sign${h.abs()}:${m.toString().padLeft(2, '0')}';
  }

  String get formattedTime {
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final m = _now.minute.toString().padLeft(2, '0');
    final period = _now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String get formattedDate {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekday = weekdays[_now.weekday - 1];
    final month = months[_now.month - 1];
    return '$weekday, $month ${_now.day}, ${_now.year} ($timezoneLabel)';
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = localNow;
      notifyListeners();
    });
  }

  SessionStatus _sessionStatus = SessionStatus.notStarted;
  SessionStatus get sessionStatus => _sessionStatus;
  String? _activeSessionId;
  String? _classDocId;
  String? _classTeacherId;
  List<String> _enrolledStudentUIDs = [];
  DateTime _sessionStartTime = DateTime(0);
  int _onTimeMinutes = 15;
  int _scanCooldownSeconds = 10;
  int _timeOutMinimumSeconds = 300;
  bool _locationValidation = false;
  int _proximityThreshold = 200;
  double? _kioskLat;
  double? _kioskLng;
  bool _kioskLocationWarning = false;
  bool get kioskLocationWarning => _kioskLocationWarning;
  void clearKioskLocationWarning() {
    _kioskLocationWarning = false;
  }

  bool _remotelyEnded = false;
  bool get remotelyEnded => _remotelyEnded;
  void clearRemotelyEnded() {
    _remotelyEnded = false;
  }

  StreamSubscription? _sessionDocListener;
  String get sessionStatusLabel {
    switch (_sessionStatus) {
      case SessionStatus.notStarted:
        return 'Not Started';
      case SessionStatus.running:
        return 'Running';
      case SessionStatus.ended:
        return 'Ended';
    }
  }

  String _classCode = '';
  String get classCode => _classCode;
  String _teacherName = '';
  String get teacherName => _teacherName;
  bool get isTeacherVerified => _teacherName.isNotEmpty;
  void updateClassCode(String value) {
    _classCode = value;
    notifyListeners();
  }

  MobileScannerController? scannerController;
  bool _isCameraActive = false;
  bool get isCameraActive => _isCameraActive;
  CameraFacing _currentFacing = CameraFacing.back;
  CameraFacing get _defaultFacing {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return CameraFacing.front;
    }
    return CameraFacing.back;
  }

  Future<bool> openCamera({CameraFacing? facing}) async {
    if (_isCameraActive) await closeCamera();
    _currentFacing = facing ?? _defaultFacing;
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: _currentFacing,
    );
    try {
      await scannerController?.start();
      _isCameraActive = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isCameraActive = false;
      scannerController?.dispose();
      scannerController = null;
      showToast(
        KioskToast(
          title: 'Camera Error',
          message: 'Could not open camera. Check permissions.',
          isError: true,
        ),
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> closeCamera() async {
    await scannerController?.stop();
    scannerController?.dispose();
    scannerController = null;
    _isCameraActive = false;
    notifyListeners();
  }

  bool _scanCooldown = false;
  void onQrDetected(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      debugPrint('QR RAW: ${b.rawValue}');
    }
    if (_scanCooldown) return;
    if (_sessionStatus != SessionStatus.running) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    _handleQrPayload(barcode.rawValue!);
    _scanCooldown = true;
    Timer(const Duration(seconds: 2), () => _scanCooldown = false);
  }

  Future<void> _handleQrPayload(String raw) async {
    final parts = raw.split('|');
    if (parts.length < 2 || parts[0] != 'CLASSSCAN') {
      showToast(
        KioskToast(
          title: 'Invalid QR Code',
          message: 'This QR code is not recognized.',
          isError: true,
        ),
      );
      return;
    }
    final uid = parts[1];
    if (parts.length >= 3) {
      final segment = parts[2];
      final isDate = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(segment);
      if (isDate) {
        final today = _formatDateForQr(localNow);
        if (segment != today) {
          showToast(
            KioskToast(
              title: 'Expired QR Code',
              message: 'This QR is not valid for today.',
              isError: true,
            ),
          );
          return;
        }
      }
    }
    final deviceUUID = parts.length >= 4 ? parts[3] : null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        showToast(
          KioskToast(
            title: 'User Not Found',
            message: 'No account found for this QR code.',
            isError: true,
          ),
        );
        return;
      }
      final user = KioskUser.fromDoc(uid, doc.data()!);
      if (user.role == 'teacher') {
        await _handleTeacherScan(user, parts);
      } else if (user.role == 'student') {
        await _handleStudentScan(user, parts, deviceUUID);
      } else {
        showToast(
          KioskToast(
            title: 'Unknown Role',
            message: 'This account has an unrecognized role.',
            isError: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('Firestore lookup error: $e');
      showToast(
        KioskToast(
          title: 'Error',
          message: 'Could not verify user. Check connection.',
          isError: true,
        ),
      );
    }
  }

  Future<void> _handleTeacherScan(KioskUser teacher, List<String> parts) async {
    if (_classTeacherId == null) {
      showToast(
        KioskToast(
          title: 'Class Not Loaded',
          message: 'Class data is not available.',
          isError: true,
        ),
      );
      return;
    }
    if (teacher.uid != _classTeacherId) {
      showToast(
        KioskToast(
          title: 'Wrong Teacher',
          message: 'This QR does not match the class teacher.',
          isError: true,
        ),
      );
      return;
    }
    if (parts.length >= 3) {
      final segment = parts[2];
      final isDate = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(segment);
      if (!isDate) {
        try {
          final userDoc = await _db.collection('users').doc(teacher.uid).get();
          final storedToken = userDoc.data()?['qrToken'] as String?;
          if (storedToken == null || storedToken != segment) {
            showToast(
              KioskToast(
                title: 'Invalid QR Code',
                message:
                    'This QR code is no longer valid. '
                    'Please use your latest QR from Settings.',
                isError: true,
              ),
            );
            return;
          }
        } catch (e) {
          showToast(
            KioskToast(
              title: 'Verification Failed',
              message: 'Could not verify teacher QR. Check connection.',
              isError: true,
            ),
          );
          return;
        }
      }
    }
    _teacherName = teacher.fullName;
    if (_activeSessionId != null) {
      await _db.collection('sessions').doc(_activeSessionId).update({
        'teacherVerified': true,
        'teacherID': teacher.uid,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    }
    showToast(
      KioskToast(
        title: 'Teacher QR Scanned',
        message: 'Welcome, ${teacher.fullName}!',
      ),
    );
    notifyListeners();
  }

  final Set<String> _processingUIDs = {};
  Future<void> _handleStudentScan(
    KioskUser student,
    List<String> parts,
    String? deviceUUID,
  ) async {
    if (_activeSessionId == null) return;
    if (deviceUUID != null && deviceUUID.isNotEmpty) {
      final existingUid = _deviceUidMap[deviceUUID];
      if (existingUid != null && existingUid != student.uid) {
        showToast(
          KioskToast(
            title: 'Device Already Used',
            message:
                'This device was already used to scan a different '
                'student this session.',
            isError: true,
          ),
        );
        return;
      }
    }
    if (_locationValidation && _kioskLat != null) {
      if (parts.length < 5 || parts[4].isEmpty) {
        showToast(
          KioskToast(
            title: 'Location Required',
            message:
                'This class requires location validation. '
                'Please allow location access and regenerate your QR.',
            isError: true,
          ),
        );
        return;
      }
      final locParts = parts[4].split(',');
      if (locParts.length != 2) {
        showToast(
          KioskToast(
            title: 'Invalid Location',
            message: 'Could not read location data from QR code.',
            isError: true,
          ),
        );
        return;
      }
      final studentLat = double.tryParse(locParts[0]);
      final studentLng = double.tryParse(locParts[1]);
      if (studentLat == null || studentLng == null) {
        showToast(
          KioskToast(
            title: 'Invalid Location',
            message: 'Could not read location data from QR code.',
            isError: true,
          ),
        );
        return;
      }
      final distance = _haversineDistance(
        _kioskLat!,
        _kioskLng!,
        studentLat,
        studentLng,
      );
      if (distance > _proximityThreshold) {
        showToast(
          KioskToast(
            title: 'Too Far from Kiosk',
            message:
                '${distance.round()}m away — limit is ${_proximityThreshold}m.',
            isError: true,
          ),
        );
        return;
      }
    }
    if (!_enrolledStudentUIDs.contains(student.uid)) {
      showToast(
        KioskToast(
          title: 'Not Enrolled',
          message: '${student.fullName} is not a student of this class.',
          isError: true,
        ),
      );
      return;
    }
    if (_timedOutLog.contains(student.uid)) {
      showToast(
        KioskToast(
          title: 'Already Completed',
          message: '${student.fullName} has already timed in and out.',
          isError: true,
        ),
      );
      return;
    }
    final lastScan = _perStudentCooldown[student.uid];
    if (lastScan != null) {
      final elapsed = DateTime.now().difference(lastScan).inSeconds;
      if (elapsed < _scanCooldownSeconds) {
        return;
      }
    }
    _perStudentCooldown[student.uid] = DateTime.now();
    if (_processingUIDs.contains(student.uid)) return;
    _processingUIDs.add(student.uid);
    try {
      final attendanceRef = _db
          .collection('sessions')
          .doc(_activeSessionId)
          .collection('attendance')
          .doc(student.uid);
      final existing = await attendanceRef.get();
      final data = existing.data();
      final firestoreTimeIn = data?['timeIn'] as Timestamp?;
      final firestoreTimeOut = data?['timeOut'];
      if (firestoreTimeIn != null && firestoreTimeOut != null) {
        _timedOutLog.add(student.uid);
        showToast(
          KioskToast(
            title: 'Already Completed',
            message: '${student.fullName} has already timed in and out.',
            isError: true,
          ),
        );
        return;
      }
      if (firestoreTimeIn != null && firestoreTimeOut == null) {
        if (!_timeInLog.containsKey(student.uid)) {
          _timeInLog[student.uid] = firestoreTimeIn.toDate();
        }
        final secondsElapsed = DateTime.now()
            .difference(_timeInLog[student.uid]!)
            .inSeconds;
        if (secondsElapsed < _timeOutMinimumSeconds) {
          final remaining = _timeOutMinimumSeconds - secondsElapsed;
          final mins = remaining ~/ 60;
          final secs = remaining % 60;
          final minLabel = mins == 1 ? 'min' : 'mins';
          final secLabel = secs == 1 ? 'sec' : 'secs';
          final display = mins > 0
              ? '$mins $minLabel $secs $secLabel'
              : '$secs $secLabel';
          showToast(
            KioskToast(
              title: 'Too Soon',
              message: 'Please wait $display before timing out.',
              isError: true,
            ),
          );
          return;
        }
        final timeOutNow = DateTime.now();
        final originalTimeIn = _timeInLog[student.uid] ?? timeOutNow;
        final minutesLate = originalTimeIn
            .difference(_sessionStartTime)
            .inMinutes;
        final timeOutStatus = minutesLate <= _onTimeMinutes
            ? 'Present (On-Time)'
            : 'Present (Late)';
        await attendanceRef.update({
          'timeOut': Timestamp.fromDate(timeOutNow),
          'status': timeOutStatus,
          'source': 'kiosk',
        });
        _timeInLog.remove(student.uid);
        _timedOutLog.add(student.uid);
        if (_scannedStudents.containsKey(student.uid)) {
          _scannedStudents[student.uid]!['timeOut'] = timeOutNow;
        }
        showToast(
          KioskToast(
            title: 'Time Out Logged',
            message: 'Goodbye, ${student.fullName}!',
          ),
        );
        return;
      }
      final timeInNow = DateTime.now();
      _timeInLog[student.uid] = timeInNow;
      if (deviceUUID != null && deviceUUID.isNotEmpty) {
        _deviceUidMap[deviceUUID] = student.uid;
      }
      _scannedStudents[student.uid] = {
        'fullName': student.fullName,
        'timeIn': timeInNow,
        'timeOut': null,
      };
      final minutesLate = timeInNow.difference(_sessionStartTime).inMinutes;
      final timeInStatus = minutesLate <= _onTimeMinutes
          ? 'Present (On-Time)'
          : 'Present (Late)';
      await attendanceRef.set({
        'timeIn': Timestamp.fromDate(timeInNow),
        'timeOut': null,
        'status': timeInStatus,
        'source': 'kiosk',
      });
      showToast(
        KioskToast(
          title: 'Time In Logged',
          message: 'Welcome, ${student.fullName}!',
        ),
      );
    } finally {
      _processingUIDs.remove(student.uid);
      notifyListeners();
    }
  }

  final Map<String, DateTime> _timeInLog = {};
  final Set<String> _timedOutLog = {};
  final Map<String, DateTime> _perStudentCooldown = {};
  final Map<String, Map<String, dynamic>> _scannedStudents = {};
  final Map<String, String> _deviceUidMap = {};
  String _formatDateForQr(DateTime dt) {
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchKioskLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _kioskLat = null;
        _kioskLng = null;
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));
      _kioskLat = pos.latitude;
      _kioskLng = pos.longitude;
    } catch (_) {
      _kioskLat = null;
      _kioskLng = null;
    }
  }

  double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;
  Future<void> startSession({CameraFacing? cameraFacing}) async {
    if (_classCode.trim().isEmpty) {
      showToast(
        KioskToast(
          title: 'No Class Code',
          message: 'Please enter a class code before starting.',
          isError: true,
        ),
      );
      return;
    }
    try {
      final classDoc = await _db
          .collection('classes')
          .doc(_classCode.trim())
          .get();
      if (!classDoc.exists) {
        showToast(
          KioskToast(
            title: 'Class Not Found',
            message: 'No class matches the code "$_classCode".',
            isError: true,
          ),
        );
        return;
      }
      final classData = classDoc.data()!;
      _classDocId = classDoc.id;
      _classTeacherId = classData['teacherID'] as String?;
      _enrolledStudentUIDs = List<String>.from(
        classData['enrolledStudents'] ?? [],
      );
      final settingsMap =
          classData['attendanceSettings'] as Map<String, dynamic>?;
      _onTimeMinutes = (settingsMap?['onTimeMinutes'] as num?)?.toInt() ?? 15;
      _scanCooldownSeconds =
          (settingsMap?['scanCooldownSeconds'] as num?)?.toInt() ?? 10;
      _timeOutMinimumSeconds =
          ((settingsMap?['timeOutMinimumMinutes'] as num?)?.toInt() ?? 5) * 60;
      _locationValidation =
          (settingsMap?['locationValidation'] as bool?) ?? false;
      _proximityThreshold =
          (settingsMap?['proximityThreshold'] as num?)?.toInt() ?? 200;
      if (_locationValidation) {
        await _fetchKioskLocation();
        if (_kioskLat == null) {
          _kioskLocationWarning = true;
        }
      }
      final openSessionSnap = await _db
          .collection('sessions')
          .where('classID', isEqualTo: _classDocId)
          .where('endTime', isNull: true)
          .where('teacherVerified', isEqualTo: true)
          .limit(1)
          .get();
      if (openSessionSnap.docs.isNotEmpty) {
        final candidateDoc = await openSessionSnap.docs.first.reference.get();
        final endTimeValue = candidateDoc.data()?['endTime'];
        if (endTimeValue != null) {
          debugPrint('Race window closed: session already ended, proceeding.');
        } else {
          showToast(
            KioskToast(
              title: 'Session Already Running',
              message:
                  'This class already has an active session. '
                  'End it from the Teacher Dashboard first.',
              isError: true,
            ),
          );
          return;
        }
      }
      final cameraOk = await openCamera(facing: cameraFacing);
      if (!cameraOk) {
        return;
      }
      final sessionRef = await _db.collection('sessions').add({
        'classID': _classDocId,
        'date': _formatDateForQr(localNow),
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'teacherVerified': false,
        'teacherID': null,
      });
      _activeSessionId = sessionRef.id;
      _sessionStartTime = localNow;
      _sessionStatus = SessionStatus.running;
      _startRemoteEndListener(sessionRef.id);
      showToast(
        KioskToast(
          title: 'Session Started',
          message: 'QR code scanning is now open.',
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('startSession error: $e');
      showToast(
        KioskToast(
          title: 'Error',
          message: 'Could not start session. Check connection.',
          isError: true,
        ),
      );
    }
  }

  List<Map<String, String>> getScannedStudentsExport() {
    String fmt(DateTime? dt) {
      if (dt == null) return 'N/A';
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $period';
    }

    return _scannedStudents.entries.map((e) {
      return {
        'Name': e.value['fullName'] as String,
        'Time In': fmt(e.value['timeIn'] as DateTime?),
        'Time Out': fmt(e.value['timeOut'] as DateTime?),
        'Status': 'Present',
        'Remark': '',
      };
    }).toList();
  }

  void _startRemoteEndListener(String sessionId) {
    _sessionDocListener?.cancel();
    _sessionDocListener = _db
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists) return;
          if (_sessionStatus != SessionStatus.running) return;
          final data = snap.data();
          if (data == null) return;
          final endTime = data['endTime'];
          if (endTime != null) {
            _remotelyEnded = true;
            endSession(remoteTriggered: true);
          }
        });
  }

  Future<void> endSession({
    bool deleteUnverified = false,
    bool remoteTriggered = false,
  }) async {
    _sessionDocListener?.cancel();
    _sessionDocListener = null;
    _sessionStatus = SessionStatus.ended;
    closeCamera();
    if (_activeSessionId != null && !remoteTriggered) {
      try {
        if (!isTeacherVerified && deleteUnverified) {
          await _db.collection('sessions').doc(_activeSessionId).delete();
        } else {
          await _db.collection('sessions').doc(_activeSessionId).update({
            'endTime': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('endSession Firestore error: $e');
      }
    }
    if (!remoteTriggered && isTeacherVerified) {
      showToast(
        KioskToast(
          title: 'Session Ended',
          message: 'QR code scanning is now closed.',
        ),
      );
    }
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _sessionStatus = SessionStatus.notStarted;
      _classCode = '';
      _teacherName = '';
      _classDocId = null;
      _classTeacherId = null;
      _activeSessionId = null;
      _enrolledStudentUIDs = [];
      _sessionStartTime = DateTime(0);
      _onTimeMinutes = 15;
      _scanCooldownSeconds = 10;
      _timeOutMinimumSeconds = 300;
      _locationValidation = false;
      _proximityThreshold = 200;
      _kioskLat = null;
      _kioskLng = null;
      _kioskLocationWarning = false;
      _remotelyEnded = false;
      _timeInLog.clear();
      _timedOutLog.clear();
      _perStudentCooldown.clear();
      _scannedStudents.clear();
      _deviceUidMap.clear();
      notifyListeners();
    });
  }

  KioskToast? _pendingToast;
  KioskToast? get pendingToast => _pendingToast;
  void showToast(KioskToast toast) {
    _pendingToast = toast;
    notifyListeners();
  }

  void clearPendingToast() {
    _pendingToast = null;
  }

  KioskController() {
    _now = localNow;
    _startClock();
  }
  @override
  void dispose() {
    _clockTimer?.cancel();
    _sessionDocListener?.cancel();
    scannerController?.dispose();
    super.dispose();
  }
}
