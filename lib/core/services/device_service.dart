import 'package:web/web.dart' as web;

class DeviceService {
  static const _key = 'classscan_device_uuid';
  static String? _cachedUUID;
  static String get deviceUUID {
    if (_cachedUUID != null) return _cachedUUID!;
    final stored = web.window.localStorage.getItem(_key);
    if (stored != null && stored.isNotEmpty) {
      _cachedUUID = stored;
      return _cachedUUID!;
    }
    final ua = web.window.navigator.userAgent;
    final sw = web.window.screen.width.toInt();
    final sh = web.window.screen.height.toInt();
    final tz = _getTimezone();
    final uuid = '$ua|$sw|$sh|$tz';
    web.window.localStorage.setItem(_key, uuid);
    _cachedUUID = uuid;
    return _cachedUUID!;
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
