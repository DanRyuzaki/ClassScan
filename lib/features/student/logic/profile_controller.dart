import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/device_service.dart';

enum ProfileStatus { idle, loading, success, error }

class StudentProfileController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _firstName = '';
  String _middleName = '';
  String _lastName = '';
  String _email = '';
  String _emoji = '🧑‍🎓';
  String get firstName => _firstName;
  String get middleName => _middleName;
  String get lastName => _lastName;
  String get email => _email;
  String get emoji => _emoji;
  String get uid => _auth.currentUser?.uid ?? '';
  String get displayName {
    return [
      _firstName,
      _middleName,
      _lastName,
    ].where((s) => s.trim().isNotEmpty).join(' ');
  }

  bool _qrVisible = false;
  bool get qrVisible => _qrVisible;
  String? _locationPayload;
  bool _locationFetching = false;
  bool get locationFetching => _locationFetching;
  bool? get locationStatus =>
      _locationPayload != null ? true : (_locationFetching ? null : false);
  void toggleQr() {
    _qrVisible = !_qrVisible;
    notifyListeners();
  }

  Future<bool> refreshLocationAndQr() async {
    _locationFetching = true;
    _locationPayload = null;
    notifyListeners();
    await _fetchLocation();
    _locationFetching = false;
    notifyListeners();
    return _locationPayload != null;
  }

  Future<void> _fetchLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 8));
      _locationPayload =
          '${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}';
    } catch (_) {
      _locationPayload = null;
    }
    notifyListeners();
  }

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String get qrPayload {
    final base = 'CLASSSCAN|$uid|$_todayDate|${DeviceService.deviceUUID}';
    if (_locationPayload != null) return '$base|$_locationPayload';
    return base;
  }

  String get todayDateDisplay => _todayDate;
  ProfileStatus _status = ProfileStatus.idle;
  ProfileStatus get status => _status;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? _successMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _status == ProfileStatus.loading;
  void _setLoading() {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = ProfileStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  void _setSuccess(String msg) {
    _status = ProfileStatus.success;
    _successMessage = msg;
    notifyListeners();
  }

  void clearStatus() {
    _status = ProfileStatus.idle;
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
        _emoji = data['emoji'] ?? '🧑‍🎓';
      } else {
        _email = user.email ?? '';
        _firstName = user.displayName ?? '';
      }
      _status = ProfileStatus.idle;
      notifyListeners();
    } catch (e) {
      debugPrint('StudentProfile loadProfile error: $e');
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
      debugPrint('saveProfile error: $e');
      _setError('Failed to save profile. Please try again.');
    }
  }

  StudentProfileController() {
    loadProfile();
  }
}
