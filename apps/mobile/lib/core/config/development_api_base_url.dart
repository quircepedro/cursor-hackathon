import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Último recurso: adb reverse tcp:3000 tcp:3000 hace que 127.0.0.1 en el móvil llegue al Mac.
const String kDevelopmentPhysicalDeviceFallbackBaseUrl =
    'http://127.0.0.1:3000/api/v1';

const _prefsDiscoveredBase = 'votio_dev_api_base';
const _prefsDiscoveredTime = 'votio_dev_api_base_time';

bool _looksLikeAndroidEmulator(AndroidDeviceInfo a) {
  final m = a.model.toLowerCase();
  final p = a.product.toLowerCase();
  final f = a.fingerprint.toLowerCase();
  return m.contains('sdk_gphone') ||
      m.contains('emulator') ||
      p.contains('sdk_gphone') ||
      p.contains('emulator') ||
      p.contains('simulator') ||
      f.contains('generic') ||
      f.contains('test-keys');
}

bool _is172Private(String a) {
  if (!a.startsWith('172.')) return false;
  final p = a.split('.');
  if (p.length < 2) return false;
  final second = int.tryParse(p[1]) ?? 0;
  return second >= 16 && second <= 31;
}

/// Primera IPv4 privada del teléfono (Wi‑Fi) para deducir la subred /24.
Future<String?> _firstPrivateLanIpv4() async {
  try {
    final interfaces =
        await NetworkInterface.list(includeLinkLocal: false);
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.type != InternetAddressType.IPv4 || addr.isLoopback) {
          continue;
        }
        final a = addr.address;
        if (a.startsWith('192.168.') ||
            a.startsWith('10.') ||
            _is172Private(a)) {
          return a;
        }
      }
    }
  } catch (_) {}
  return null;
}

Future<bool> _tcpPortOpen(String host, int port) async {
  Socket? s;
  try {
    s = await Socket.connect(
      host,
      port,
      timeout: const Duration(milliseconds: 200),
    );
    return true;
  } catch (_) {
    return false;
  } finally {
    s?.destroy();
  }
}

/// Busca Nest (puerto 3000) en la misma subred /24 que el móvil.
Future<String?> _probeNestOnSubnet(String phoneIp) async {
  final parts = phoneIp.split('.');
  if (parts.length != 4) return null;
  final myLast = int.tryParse(parts[3]);
  if (myLast == null) return null;
  final prefix = '${parts[0]}.${parts[1]}.${parts[2]}.';

  final candidates = <String>[];
  for (var last = 1; last <= 254; last++) {
    if (last == myLast) continue;
    candidates.add('$prefix$last');
  }
  int prio(String ip) {
    final last = int.parse(ip.split('.').last);
    if (last >= 2 && last <= 40) return last;
    if (last >= 100 && last <= 130) return 50 + last;
    return 200 + last;
  }
  candidates.sort((a, b) => prio(a).compareTo(prio(b)));

  const batchSize = 32;
  for (var i = 0; i < candidates.length; i += batchSize) {
    final end = i + batchSize > candidates.length
        ? candidates.length
        : i + batchSize;
    final slice = candidates.sublist(i, end);
    final hits = await Future.wait(
      slice.map((ip) async {
        final ok = await _tcpPortOpen(ip, 3000);
        return ok ? ip : null;
      }),
    );
    for (final ip in hits) {
      if (ip != null) return 'http://$ip:3000/api/v1';
    }
  }
  return null;
}

Future<String?> _tryDiscoverCachedOrScan() async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString(_prefsDiscoveredBase);
  final t = prefs.getInt(_prefsDiscoveredTime) ?? 0;
  if (cached != null && cached.isNotEmpty) {
    final age = DateTime.now().millisecondsSinceEpoch - t;
    if (age < const Duration(days: 7).inMilliseconds) {
      return cached;
    }
  }
  final phoneIp = await _firstPrivateLanIpv4();
  if (phoneIp == null) return null;
  final found = await _probeNestOnSubnet(phoneIp);
  if (found != null) {
    await prefs.setString(_prefsDiscoveredBase, found);
    await prefs.setInt(_prefsDiscoveredTime, DateTime.now().millisecondsSinceEpoch);
  }
  return found;
}

/// En emulador Android, 127.0.0.1/localhost → 10.0.2.2 (host del Mac).
String _rewriteAndroidLocalhostForEmulator(
  String url,
  AndroidDeviceInfo android,
) {
  final asEmu = !android.isPhysicalDevice || _looksLikeAndroidEmulator(android);
  if (!asEmu) return url;
  try {
    final uri = Uri.parse(url);
    final h = uri.host.toLowerCase();
    if (h == '127.0.0.1' || h == 'localhost') {
      return uri.replace(host: '10.0.2.2').toString();
    }
  } catch (_) {}
  return url;
}

Future<String> _replaceLoopbackOnPhysicalAndroid(
  String url,
  AndroidDeviceInfo android,
) async {
  final physical = android.isPhysicalDevice && !_looksLikeAndroidEmulator(android);
  if (!physical) return url;

  try {
    final uri = Uri.parse(url);
    final h = uri.host.toLowerCase();
    if (h != '127.0.0.1' && h != 'localhost') return url;
  } catch (_) {
    return url;
  }

  const lanHost = String.fromEnvironment('VOTIO_LAN_HOST', defaultValue: '');
  if (lanHost.isNotEmpty) {
    try {
      return Uri.parse(url).replace(host: lanHost).toString();
    } catch (_) {}
  }

  final discovered = await _tryDiscoverCachedOrScan();
  return discovered ?? url;
}

Future<String> _replaceLoopbackOnPhysicalIos(String url) async {
  final ios = await DeviceInfoPlugin().iosInfo;
  if (!ios.isPhysicalDevice) return url;
  try {
    final uri = Uri.parse(url);
    final h = uri.host.toLowerCase();
    if (h != '127.0.0.1' && h != 'localhost') return url;
  } catch (_) {
    return url;
  }

  const lanHost = String.fromEnvironment('VOTIO_LAN_HOST', defaultValue: '');
  if (lanHost.isNotEmpty) {
    try {
      return Uri.parse(url).replace(host: lanHost).toString();
    } catch (_) {}
  }

  final discovered = await _tryDiscoverCachedOrScan();
  return discovered ?? url;
}

/// Resuelve la URL del API en desarrollo.
///
/// Prioridad: `dart-define=API_BASE_URL` → `.env` → por plataforma.
///
/// **Android físico / iPhone físico** con `127.0.0.1`: intenta `--dart-define=VOTIO_LAN_HOST=`
/// o **descubre** en la Wi‑Fi un host con puerto 3000 abierto (Nest) y lo guarda 7 días.
Future<String> resolveDevelopmentApiBaseUrlAsync() async {
  AndroidDeviceInfo? android;

  Future<AndroidDeviceInfo> loadAndroid() async {
    android ??= await DeviceInfoPlugin().androidInfo;
    return android!;
  }

  late String resolved;

  const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (fromDefine.isNotEmpty) {
    resolved = fromDefine;
  } else {
    final fromEnv = dotenv.env['API_BASE_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      resolved = fromEnv;
    } else {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await loadAndroid();
        final asEmu = !a.isPhysicalDevice || _looksLikeAndroidEmulator(a);
        if (asEmu) {
          resolved = 'http://10.0.2.2:3000/api/v1';
        } else {
          const lanHost =
              String.fromEnvironment('VOTIO_LAN_HOST', defaultValue: '');
          resolved = lanHost.isNotEmpty
              ? 'http://$lanHost:3000/api/v1'
              : kDevelopmentPhysicalDeviceFallbackBaseUrl;
        }
      } else if (Platform.isIOS) {
        final ios = await plugin.iosInfo;
        if (!ios.isPhysicalDevice) {
          resolved = 'http://127.0.0.1:3000/api/v1';
        } else {
          const lanHost =
              String.fromEnvironment('VOTIO_LAN_HOST', defaultValue: '');
          resolved = lanHost.isNotEmpty
              ? 'http://$lanHost:3000/api/v1'
              : kDevelopmentPhysicalDeviceFallbackBaseUrl;
        }
      } else {
        resolved = 'http://127.0.0.1:3000/api/v1';
      }
    }
  }

  if (Platform.isAndroid) {
    final a = await loadAndroid();
    var u = _rewriteAndroidLocalhostForEmulator(resolved, a);
    u = await _replaceLoopbackOnPhysicalAndroid(u, a);
    return u;
  }
  if (Platform.isIOS) {
    return _replaceLoopbackOnPhysicalIos(resolved);
  }
  return resolved;
}
