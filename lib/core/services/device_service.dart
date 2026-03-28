import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:web/web.dart' as web;

class DeviceService {
  static const _key = 'classscan_device_uuid';
  static String? _cachedUUID;
  static String get deviceUUID {
    if (_cachedUUID != null) return _cachedUUID!;
    final stored = web.window.localStorage.getItem(_key);
    if (stored != null && stored.isNotEmpty) {
      // Migrate legacy values that were stored as raw fingerprint strings
      // containing pipe characters (e.g. "<userAgent>|<w>|<h>|<tz>").
      // Re-hash them into a safe hex digest and persist the new form so
      // the migration only runs once.
      if (stored.contains('|')) {
        final migrated = _hashFingerprint(stored);
        web.window.localStorage.setItem(_key, migrated);
        _cachedUUID = migrated;
        return _cachedUUID!;
      }
      _cachedUUID = stored;
      return _cachedUUID!;
    }
    final ua = web.window.navigator.userAgent;
    final sw = web.window.screen.width.toInt();
    final sh = web.window.screen.height.toInt();
    final tz = _getTimezone();
    // Build the fingerprint then hash it so the stored/returned value is
    // always a 64-char hex string — guaranteed pipe-free and QR-safe.
    final fingerprint = '$ua::$sw::$sh::$tz';
    final uuid = _hashFingerprint(fingerprint);
    web.window.localStorage.setItem(_key, uuid);
    _cachedUUID = uuid;
    return _cachedUUID!;
  }

  /// Returns a SHA-256 hex digest of [input]. The result contains only
  /// lowercase hex characters [0-9a-f] and is safe to embed in a
  /// pipe-delimited QR payload.
  static String _hashFingerprint(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  static String _getTimezone() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final h = offset.inHours;
      final m = offset.inMinutes.abs() % 60;
      final sign = h >= 0 ? '+' : '-';
      return m == 0
          ? 'GMT$sign${h.abs()}'
          : 'GMT$sign${h.abs()}:${m.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'unknown';
    }
  }

  static void initialize() => deviceUUID;
}
