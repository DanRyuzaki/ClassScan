import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

enum AppPortal { main, teacher, student, kiosk }

class MainController extends ChangeNotifier {
  AppPortal _currentPortal = AppPortal.main;
  AppPortal get currentPortal => _currentPortal;
  final List<AppPortal> _navigationHistory = [AppPortal.main];
  List<AppPortal> get navigationHistory =>
      List.unmodifiable(_navigationHistory);
  bool get canGoBack => _navigationHistory.length > 1;
  late DateTime _now;
  Timer? _clockTimer;
  DateTime get now => _now;
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
    return '$weekday, $month ${_now.day}, ${_now.year}';
  }

  bool _isLoading = false;
  String _loadingMessage = '';
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  void setLoading(bool value, {String message = ''}) {
    _isLoading = value;
    _loadingMessage = message;
    notifyListeners();
  }

  bool _isFirebaseReady = false;
  String? _firebaseError;
  bool get isFirebaseReady => _isFirebaseReady;
  String? get firebaseError => _firebaseError;
  Future<void> initializeFirebase(FirebaseOptions options) async {
    setLoading(true, message: 'Initializing...');
    try {
      await Firebase.initializeApp(options: options);
      _isFirebaseReady = true;
      _firebaseError = null;
    } catch (e) {
      _isFirebaseReady = false;
      _firebaseError = e.toString();
    } finally {
      setLoading(false);
    }
  }

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

  String get fullDateTimeDisplay =>
      '$formattedTime  |  $formattedDate ($timezoneLabel)';
  void goToMain() => _navigateTo(AppPortal.main);
  void goToTeacherPortal() => _navigateTo(AppPortal.teacher);
  void goToStudentPortal() => _navigateTo(AppPortal.student);
  void goToKiosk() => _navigateTo(AppPortal.kiosk);
  void goBack() {
    if (canGoBack) {
      _navigationHistory.removeLast();
      _currentPortal = _navigationHistory.last;
      notifyListeners();
    }
  }

  void _navigateTo(AppPortal portal) {
    if (_currentPortal == portal) return;
    _currentPortal = portal;
    _navigationHistory.add(portal);
    notifyListeners();
  }

  MainController() {
    _now = localNow;
    _startClock();
  }
  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = localNow;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}
