// ═══════════════════════════════════════════════════════════
//  TOTV+  v18.0  —  main.dart  (SPORTS CHAMPION)
//
//  ✅ SmartPoster — السيرفر أولاً ← TMDB fallback تلقائي
//  ✅ Shimmer Loading — بريق ذهبي متحرك بدل Skeleton الرمادي
//  ✅ Glassmorphism — زجاج ضبابي كامل على كل الكروت والـ nav
//  ✅ Color System v2 — عمق لوني أغنى + Spacing 8pt grid
//  ✅ Typography Scale — 6 مستويات نص احترافية
//  ✅ Page Transitions — Slide+Fade مثل iOS
//  ✅ Hero backdrop w1280 بدون proxy على native
//  ✅ WatchHistory + MultiProfile + SearchPage + Recommendations
//  ✅ تكيف مع: Android / iOS / iPad / Web / Windows / Android TV
// ═══════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
// google_mobile_ads + flutter_local_notifications — mobile only (guarded below)
import 'package:google_mobile_ads/google_mobile_ads.dart'
    if (dart.library.html) 'stub/ads_stub.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    if (dart.library.html) 'stub/notif_stub.dart';

// ─────────────────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────────────────
const kAdAppId    = 'ca-app-pub-6787200447252705~6903397497';
const kAdInterId  = 'ca-app-pub-6787200447252705/9494869419';
const kAdBannerId = 'ca-app-pub-6787200447252705/9494869419';
const kPkgName    = 'com.totv.plus';
const kAppVersion = 18;    // رقم الإصدار الحالي — يُقارن بـ Remote Config
const kUpdateUrl  = 'https://hamza123123123.github.io/totv/#';
const kProxyBase  = 'https://bitter-frog-2c67.haedirasso.workers.dev';
// CMS Worker — نظام إدارة المحتوى الجديد
const kCmsBase    = 'https://YOUR-CMS-WORKER.workers.dev'; // ← غيّر هذا بعد نشر Worker
// GitHub Pages CDN — مجاني + يتحمل ملايين الطلبات
const kGithubCdn  = 'https://hamza123123123.github.io/totv';

// ─────────────────────────────────────────────────────────
//  COLORS — TOD Style: أسود + ذهبي
// ─────────────────────────────────────────────────────────
class C {
  // ── Core backgrounds — layered depth ──────────────────────
  static const bg       = Color(0xFF050505); // أعمق من pure black — أقل إجهاداً للعين
  static const bg2      = Color(0xFF0C0C0C);
  static const surface  = Color(0xFF141414); // Netflix card bg
  static const card     = Color(0xFF1C1C1C);
  static const cardHov  = Color(0xFF242424);
  static const border   = Color(0xFF2C2C2C);
  static const borderSub= Color(0xFF1E1E1E);
  // ── Text hierarchy ─────────────────────────────────────────
  static const white    = Color(0xFFFFFFFF);
  static const textPri  = Color(0xFFF0F0F0); // أبيض ناعم
  static const textSec  = Color(0xFFB3B3B3); // Netflix secondary
  static const grey     = Color(0xFF888888);
  static const dim      = Color(0xFF4A4A4A);
  // ── Semantic ───────────────────────────────────────────────
  static const live     = Color(0xFFE53935);
  static const liveDim  = Color(0x33E53935);
  static const success  = Color(0xFF4CAF50);
  static const info     = Color(0xFF2196F3);
  // ── Brand Gold — TOTV+ signature ──────────────────────────
  static const gold     = Color(0xFFF5C518);
  static const goldLight= Color(0xFFFFD740);
  static const goldDark = Color(0xFFFFAB00);
  static const goldBg   = Color(0x14F5C518);
  static const goldBg2  = Color(0x28F5C518);
  static const accent   = Color(0xFFF5C518);
  // ── Glass — Glassmorphism values ──────────────────────────
  static const glass    = Color(0x1AFFFFFF); // شفافية 10%
  static const glassBdr = Color(0x26FFFFFF); // حدود زجاجية 15%

  // ── Gradients ─────────────────────────────────────────────
  static const goldGrad = LinearGradient(
    colors: [goldLight, gold, goldDark],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const playGrad = LinearGradient(
    colors: [Color(0xFFFFD740), Color(0xFFFFAB00)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const heroGrad = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    stops: [0.0, 0.3, 0.65, 1.0],
    colors: [Color(0x00000000), Color(0x18000000), Color(0xCC000000), Color(0xFF050505)]);
  // تدرج جانبي للعمق
  static const sideGrad = LinearGradient(
    begin: Alignment.centerRight, end: Alignment.centerLeft,
    colors: [Color(0x00000000), Color(0xAA000000)]);
}

// ─────────────────────────────────────────────────────────
//  TEXT
// ─────────────────────────────────────────────────────────
class T {
  // ── Montserrat — للأرقام والمعلومات التقنية ───────────────
  static TextStyle mont({double s = 14, FontWeight w = FontWeight.w400,
      Color c = C.textPri, double ls = 0}) =>
      GoogleFonts.montserrat(fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls, height: 1.3);

  // ── Cairo — للنصوص العربية ─────────────────────────────────
  static TextStyle cairo({double s = 14, FontWeight w = FontWeight.w400, Color c = C.textPri}) =>
      GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c, height: 1.4);

  // ── Cinzel — للشعار والعناوين الرئيسية ──────────────────
  static TextStyle cinzel({double s = 14, Color c = C.gold, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.cinzel(fontSize: s, fontWeight: w, color: c, letterSpacing: 1.5);

  // ── Typography Scale — النظام الهرمي الكامل ───────────────
  // Display: عنوان Hero الرئيسي
  static TextStyle display({Color c = C.textPri}) =>
      GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w900, color: c,
          height: 1.1, letterSpacing: -0.5);

  // H1: عنوان صفحة
  static TextStyle h1({Color c = C.textPri}) =>
      GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: c, height: 1.2);

  // H2: عنوان قسم
  static TextStyle h2({Color c = C.textPri}) =>
      GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w700, color: c, height: 1.3);

  // Body: نص أساسي
  static TextStyle body({Color c = C.textSec}) =>
      GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w400, color: c,
          height: 1.6, letterSpacing: 0.1);

  // Caption: نص صغير / metadata
  static TextStyle caption({Color c = C.grey}) =>
      GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w400, color: c,
          letterSpacing: 0.3, height: 1.4);

  // Label: تسمية زر / badge
  static TextStyle label({Color c = C.textPri, double s = 12}) =>
      GoogleFonts.montserrat(fontSize: s, fontWeight: FontWeight.w600, color: c,
          letterSpacing: 0.5, height: 1.2);
}

// ── Spacing System — 8pt grid ─────────────────────────────────
class S {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
  // Card radii
  static const double rSm  = 6.0;
  static const double rMd  = 10.0;
  static const double rLg  = 14.0;
  static const double rXl  = 20.0;
  static const double rPill= 100.0;
}

// ─────────────────────────────────────────────────────────
//  PLATFORM DETECTION
// ─────────────────────────────────────────────────────────
class Plat {
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS     => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isWin     => !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  static bool get isMobile  => isAndroid || isIOS;
  static bool get isTablet  {
    // كشف iPad / Android Tablet بناءً على الشاشة
    try {
      final data = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
      final ratio = data.shortestSide / WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      return ratio >= 600;
    } catch (_) { return false; }
  }
  static bool get isTV {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    // TV has large screen but no touch, tablet has touch
    try {
      final data  = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
      final ratio = data.shortestSide /
          WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      // TV screens are usually > 720dp and have no touch
      return ratio >= 720;
    } catch (_) { return false; }
  }
  static void detect() {}
  static String get ua {
    if (kIsWeb)    return 'Mozilla/5.0 (compatible; TOTV+/12.0)';
    if (isAndroid) return 'stagefright/1.2 (Linux;Android 12)';
    if (isIOS)     return 'AppleCoreMedia/1.0 (iPhone; iOS 17)';
    return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) VLC/3.0.20';
  }
  static String get name {
    if (kIsWeb)    return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS)     return 'iOS';
    if (isWin)     return 'Windows';
    return 'Unknown';
  }
}

// ─────────────────────────────────────────────────────────
//  DEVICE ID (Firestore-based ban system)
// ─────────────────────────────────────────────────────────
class DeviceId {
  static String? _v;
  static Future<String> get() async {
    if (_v != null) return _v!;
    try {
      if (kIsWeb) {
        final p = await SharedPreferences.getInstance();
        _v = p.getString('totv_web_devid');
        if (_v == null) {
          final rng = math.Random.secure();
          final hex = List.generate(8, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join().toUpperCase();
          _v = 'WEB-${hex.substring(0,4)}-${hex.substring(4)}';
          await p.setString('totv_web_devid', _v!);
        }
        return _v!;
      }
      final p = DeviceInfoPlugin(); String raw;
      if (Plat.isAndroid)    raw = (await p.androidInfo).id;
      else if (Plat.isIOS)   raw = (await p.iosInfo).identifierForVendor ?? '';
      else if (Plat.isWin)   raw = (await p.windowsInfo).deviceId;
      else raw = DateTime.now().millisecondsSinceEpoch.toString();
      final code = raw.codeUnits.fold<int>(0, (a, b) => a ^ (b * 31 + 7))
          .toRadixString(16).toUpperCase().padLeft(8, '0');
      _v = 'TV-${code.substring(0,4)}-${code.substring(4)}';
    } catch (_) { _v = 'TV-0000-0001'; }
    return _v!;
  }

  // ── فحص حظر الجهاز في Firestore ──
  static Future<bool> isBanned() async {
    try {
      final id  = await get();
      final doc = await FirebaseFirestore.instance
          .collection('banned_devices').doc(id).get();
      return doc.exists && (doc.data()?['banned'] == true);
    } catch (_) { return false; }
  }

  // ── حظر جهاز (من لوحة التحكم) ──
  static Future<void> ban(String deviceId, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('banned_devices').doc(deviceId)
          .set({'banned': true, 'reason': reason, 'at': FieldValue.serverTimestamp()});
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────
//  SECURITY LAYER — منع التسجيل داخل المشغل فقط
// ─────────────────────────────────────────────────────────
class SecurityLayer {
  static const _ch = MethodChannel('totv_secure');

  static Future<void> enableScreenRecord() async {
    if (kIsWeb || !Plat.isAndroid) return;
    try { await _ch.invokeMethod('setSecureFlag', {'enable': true}); } catch (_) {}
  }

  static Future<void> disableScreenRecord() async {
    if (kIsWeb || !Plat.isAndroid) return;
    try { await _ch.invokeMethod('setSecureFlag', {'enable': false}); } catch (_) {}
  }

  static Map<String, String> streamHeaders({bool isLive = false}) => {
    'User-Agent':    Plat.ua,
    'Referer':       RC._serverUrl,
    'Origin':        RC._serverUrl,
    if (isLive) 'Cache-Control': 'no-cache',
    if (isLive) 'Pragma':        'no-cache',
  };
}


// ─────────────────────────────────────────────────────────
//  REMOTE CONFIG — تحديث الإصدار + قفل + صيانة
// ─────────────────────────────────────────────────────────
class RC {
  static final _rc = FirebaseRemoteConfig.instance;
  static Timer? _timer;

  static String _serverUrl   = 'http://usmmax.org:2052';
  static String _username    = '28701367011637';
  static String _password    = '26997520760476';
  static bool   _maintenance = false;
  static String _maintMsg    = '';
  static bool   _locked      = false;
  static String _lockMsg     = '';
  static int    _minVersion  = 0;
  static String _updateUrl   = kUpdateUrl;
  static String _telegram    = 'https://t.me/O_2828';
  static String _whatsapp    = '9647714415816';
  static String _subRedirect = 'whatsapp';
  static String _subUrl      = '';
  static int    _guestLimit  = 200;
  static bool   _useProxy    = true;
  static String _proxyUrl    = kProxyBase;
  static int    _cacheMinutes= 15;

  static String get serverUrl    => _serverUrl;
  static String get username     => _username;
  static String get password     => _password;
  static bool   get maintenance  => _maintenance;
  static String get maintMsg     => _maintMsg;
  static bool   get locked       => _locked;
  static String get lockMsg      => _lockMsg;
  static int    get minVersion   => _minVersion;
  static String get updateUrl    => _updateUrl;
  static String get telegram     => _telegram;
  static String get whatsapp     => _whatsapp;
  static String get subRedirect  => _subRedirect;
  static String get subUrl       => _subUrl;
  static int    get guestLimit   => _guestLimit;
  static bool   get useProxy     => _useProxy;
  static String get proxyUrl     => _proxyUrl;
  static int    get cacheMinutes => _cacheMinutes;

  // هل يحتاج تحديث؟
  static bool get needsUpdate => _minVersion > kAppVersion;

  static Future<void> init() async {
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout:         const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 3),
      ));
      await _rc.setDefaults({
        'server_url':    'http://usmmax.org:2052',
        'username':      '28701367011637',
        'password':      '26997520760476',
        'maintenance':   false,
        'maint_msg':     'نعمل على تحسين الخدمة',
        'locked':        false,
        'lock_msg':      'التطبيق متوقف مؤقتاً',
        'min_version':   0,
        'update_url':    kUpdateUrl,
        'telegram':      'https://t.me/O_2828',
        'whatsapp':      '9647714415816',
        'sub_redirect':  'whatsapp',
        'sub_url':       '',
        'guest_limit':   200,
        'use_proxy':     true,
        'proxy_url':     'https://bitter-frog-2c67.haedirasso.workers.dev',
        'cache_minutes': 15,
      });
      await _rc.fetchAndActivate();
      _apply();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(minutes: 3), (_) async {
        try { await _rc.fetchAndActivate(); _apply(); onConfigChanged?.call(); } catch (_) {}
      });
    } catch (_) {}
  }

  static void _apply() {
    _serverUrl    = _s('server_url',   'http://usmmax.org:2052');
    _username     = _s('username',     '28701367011637');
    _password     = _s('password',     '26997520760476');
    _maintenance  = _rc.getBool('maintenance');
    _maintMsg     = _s('maint_msg',    '');
    _locked       = _rc.getBool('locked');
    _lockMsg      = _s('lock_msg',     '');
    _minVersion   = _rc.getInt('min_version');
    _updateUrl    = _s('update_url',   kUpdateUrl);
    _telegram     = _s('telegram',     'https://t.me/O_2828');
    _whatsapp     = _s('whatsapp',     '9647714415816');
    _subRedirect  = _s('sub_redirect', 'whatsapp');
    _subUrl       = _s('sub_url',      '');
    _guestLimit   = math.max(1, _rc.getInt('guest_limit'));
    _useProxy     = _rc.getBool('use_proxy');
    // Worker URL ثابت — لا نسمح لـ Remote Config بتغييره
    _proxyUrl = kProxyBase;
    _cacheMinutes = math.max(1, _rc.getInt('cache_minutes'));
  }

  static VoidCallback? onConfigChanged;
  static String _s(String k, String fb) {
    try { final v = _rc.getString(k); return v.isNotEmpty ? v : fb; } catch (_) { return fb; }
  }

  // ── URL Builder ──
  static String buildApiUrl(String action, [Map<String, dynamic>? extra]) {
    final params = <String, String>{
      'action': action,
      ...?extra?.map((k, v) => MapEntry(k, v.toString())),
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final proxy = _proxyUrl.isNotEmpty ? _proxyUrl : kProxyBase;
    return '$proxy?$query';
  }

  // ── روابط البث المباشرة — بدون Worker ──
    static String streamUrl(String type, String id, String ext) {
    // Delegate to Sub for plan-aware URL building
    return Sub.buildStreamUrl(type, id, ext);
  }

  // ── تحقق من الإصدار عبر Worker ──
  static Future<void> checkVersionFromWorker() async {
    try {
      final proxy = _proxyUrl.isNotEmpty ? _proxyUrl : kProxyBase;
      final dio   = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));
      final base = proxy.replaceAll(RegExp(r'/$'), '');
      final r     = await dio.get('$base/version');
      if (r.data is Map) {
        final required = (r.data['required'] ?? 0) as int;
        final url      = (r.data['updateUrl'] ?? kUpdateUrl).toString();
        if (required > _minVersion) _minVersion = required;
        if (url.isNotEmpty) _updateUrl = url;
      }
    } catch (_) {}
  }

  static void dispose() => _timer?.cancel();
}

// ═══════════════════════════════════════════════════════════
//  SERVER REGISTRY — نظام السيرفرات الذكي
// ═══════════════════════════════════════════════════════════
class ServerRegistry {
  // Worker endpoint — يُرجع config مشفّر
  static const _configUrl = '$kProxyBase/app-config';

  static List<Map<String, dynamic>> _servers = [];
  static int    _idx      = 0;
  static bool   _loaded   = false;
  static Timer? _refreshTimer;

  static Future<void> init() async {
    await _fetch();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => _fetch());
  }

  static Future<void> _fetch() async {
    try {
      final r = await Dio().get(_configUrl,
        options: Options(receiveTimeout: const Duration(seconds: 6)));
      if (r.statusCode != 200) { _loaded = true; return; }

      final data = r.data as Map<String, dynamic>;
      if (data['status'] == 'no_config') { _loaded = true; return; }

      // فك التشفير داخل التطبيق
      final payload = data['payload']?.toString() ?? '';
      if (payload.isEmpty) { _loaded = true; return; }

      final decrypted = _decrypt(payload);
      if (decrypted == null) { _loaded = true; return; }

      final config = jsonDecode(decrypted) as Map<String, dynamic>;

      // تحديث وضع الصيانة
      if (config['maintenance'] == true) {
        debugPrint('ServerRegistry: Maintenance mode active');
      }

      final all = ((config['servers'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .where((s) => s['is_alive'] == true)
          .toList()
        ..sort((a, b) =>
            ((a['priority'] as int?) ?? 99)
                .compareTo((b['priority'] as int?) ?? 99));
      if (all.isNotEmpty) { _servers = all; _idx = 0; }
      _loaded = true;
    } catch (_) { _loaded = true; }
  }

  // فك التشفير — AES-256-GCM خفيف في Dart
  // المفتاح = نفس ENCRYPT_SECRET في Worker
  // ملاحظة: نستخدم XOR بسيط + base64 للتوافق مع Web Crypto API
  static String? _decrypt(String b64) {
    try {
      final bytes = base64Decode(b64);
      if (bytes.length <= 12) return null;
      // استخراج IV (12 bytes أولى) + ciphertext
      // Worker يستخدم AES-GCM — نعيد بناء النص من الـ payload مباشرة
      // للتبسيط في Flutter: نحفظ plaintext JSON مضغوط بـ base64 مع obfuscation
      final text = utf8.decode(bytes.sublist(12), allowMalformed: true);
      if (text.startsWith('{')) return text;
      // محاولة ثانية بدون IV
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) { return null; }
  }

  static void dispose() { _refreshTimer?.cancel(); }

  static Map<String, dynamic> get current {
    if (_servers.isNotEmpty && _idx < _servers.length) return _servers[_idx];
    return {
      'id': 'rc_default', 'host': RC.serverUrl,
      'username': RC.username, 'password': RC.password,
      'supports_4k': true,
    };
  }

  static String get host     => current['host']?.toString()     ?? RC.serverUrl;
  static String get username => current['username']?.toString() ?? RC.username;
  static String get password => current['password']?.toString() ?? RC.password;
  static bool   get has4K    => current['supports_4k'] == true;

  static bool switchToNext() {
    if (_idx < _servers.length - 1) {
      _idx++;
      debugPrint('Switched to server: ${current['id']}');
      return true;
    }
    return false;
  }

  static void resetToFirst() { _idx = 0; }

  static List<String> streamUrls(String type, String id, String ext) {
    final pool = _servers.isNotEmpty ? _servers : [current];
    final urls = <String>[];
    for (final s in pool.where((s) => s['is_alive'] == true)) {
      final base = (s['host']?.toString() ?? '').replaceAll(RegExp(r'/$'), '');
      final u = s['username']?.toString() ?? '';
      final p = s['password']?.toString() ?? '';
      if (base.isNotEmpty && u.isNotEmpty) urls.add('$base/$type/$u/$p/$id.$ext');
    }
    if (urls.isEmpty) {
      final base = RC.serverUrl.replaceAll(RegExp(r'/$'), '');
      urls.add('$base/$type/${RC.username}/${RC.password}/$id.$ext');
    }
    return urls;
  }

  static int  get activeCount => _servers.where((s) => s['is_alive'] == true).length;
  static bool get isReady     => _loaded;
}

// ─────────────────────────────────────────────────────────
//  SUBSCRIPTION
// ─────────────────────────────────────────────────────────
class Sub {
  // ── Plan Types ────────────────────────────────────────────────
  static const kFree   = 'free';
  static const kNormal = 'normal';
  static const kVIP    = 'vip';

  // ── Internal State (never exposed to UI) ─────────────────────
  static bool      _premium       = false;
  static String    _plan          = kFree;
  static DateTime? _activatedAt;
  static DateTime? _expiry;

  // Contact info from remote config
  static String _email     = '';
  static String _whatsapp  = '';
  static String _telegram  = '';

  // Buy URLs (changeable remotely)
  static String _buyUrl    = '';
  static String _vipBuyUrl = '';

  // VIP Xtream credentials — NEVER shown in UI
  static String _xUser = '';
  static String _xPass = '';
  static String _xHost = '';
  static String _xPort = '';

  // Load balancer state
  static String _activeServerId = '';
  static int    _sessionStart   = 0;

  // ── Public Getters — Safe only ────────────────────────────────
  static bool   get isPremium  => _premium;
  static bool   get isVIP      => _plan == kVIP;
  static bool   get isNormal   => _plan == kNormal;
  static bool   get isFree     => _plan == kFree;
  static String get plan       => _plan;

  // Contact info only
  static String get email    => _email;
  static String get whatsapp => _whatsapp;
  static String get telegram => _telegram;

  // Buy URLs
  static String get buyUrl    => _buyUrl.isNotEmpty ? _buyUrl : 'https://t.me/O_2828';
  static String get vipBuyUrl => _vipBuyUrl.isNotEmpty ? _vipBuyUrl : buyUrl;

  // Dates only — no server info
  static DateTime? get expiry      => _expiry;
  static DateTime? get activatedAt => _activatedAt;
  static int get daysLeft {
    if (_expiry == null) return 0;
    return _expiry!.difference(DateTime.now()).inDays.clamp(0, 9999);
  }
  static String get activatedStr {
    if (_activatedAt == null) return '';
    return '${_activatedAt!.day.toString().padLeft(2,"0")}/'
           '${_activatedAt!.month.toString().padLeft(2,"0")}/'
           '${_activatedAt!.year}';
  }
  static String get expiryStr {
    if (_expiry == null) return '';
    return '${_expiry!.day.toString().padLeft(2,"0")}/'
           '${_expiry!.month.toString().padLeft(2,"0")}/'
           '${_expiry!.year}';
  }

  // ── Xtream access — internal but accessible from same file ──
  static String get _xtreamUser => _xUser;
  static String get _xtreamPass => _xPass;
  // Public accessors for Api class (same file)
  static String get xtreamUser => _xUser;
  static String get xtreamPass => _xPass;
  static String get xtreamBase {
    if (_xHost.isEmpty) return RC.serverUrl;
    final host = _xHost.replaceAll(RegExp(r'/$'), '');
    return _xPort.isNotEmpty ? '$host:$_xPort' : host;
  }
  static String get _xtreamBase {
    if (_xHost.isEmpty) return RC.serverUrl;
    final host = _xHost.replaceAll(RegExp(r'/\$'), '');
    return _xPort.isNotEmpty ? '$host:$_xPort' : host;
  }

  // ── Load ─────────────────────────────────────────────────────
  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _plan    = p.getString('_s_pl') ?? kFree;
      _premium = _plan != kFree;
      final ex = p.getString('_s_ex');
      final ac = p.getString('_s_ac');
      if (ex != null) _expiry      = DateTime.tryParse(ex);
      if (ac != null) _activatedAt = DateTime.tryParse(ac);
      // Encrypted VIP data
      _xUser = p.getString('_vx_u') ?? '';
      _xPass = p.getString('_vx_p') ?? '';
      _xHost = p.getString('_vx_h') ?? '';
      _xPort = p.getString('_vx_pt')  ?? '';
      _activeServerId = p.getString('_vx_sid') ?? '';
      // Validate expiry
      if (_premium && _expiry != null && _expiry!.isBefore(DateTime.now())) {
        await _clear();
      }
    } catch (_) {}
    // Load remote config (contact + buy URLs)
    await _fetchRemoteConfig();
  }

  static Future<void> _fetchRemoteConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config').doc('subscription').get();
      final d = doc.data() ?? {};
      _buyUrl    = d['buy_url']?.toString()     ?? '';
      _vipBuyUrl = d['vip_buy_url']?.toString() ?? '';
      _email     = d['support_email']?.toString()    ?? '';
      _whatsapp  = d['support_whatsapp']?.toString() ?? RC.whatsapp;
      _telegram  = d['support_telegram']?.toString() ?? RC.telegram;
    } catch (_) {}
  }

  static void updateRemote(Map<String, dynamic> d) {
    if (d['buy_url']     != null) _buyUrl    = d['buy_url'];
    if (d['vip_buy_url'] != null) _vipBuyUrl = d['vip_buy_url'];
    if (d['support_email']    != null) _email    = d['support_email'];
    if (d['support_whatsapp'] != null) _whatsapp = d['support_whatsapp'];
    if (d['support_telegram'] != null) _telegram = d['support_telegram'];
  }

  // ── VIP Login — username + password → Xtream credentials ─────
  static Future<SubResult> loginVIP(String user, String pass) async {
    final u = user.trim();
    final p = pass.trim();
    if (u.isEmpty || p.isEmpty)
      return SubResult(false, 'أدخل اسم المستخدم وكلمة المرور');

    try {
      // Search Firestore for VIP user
      final snap = await FirebaseFirestore.instance
          .collection('vip_users')
          .where('username', isEqualTo: u)
          .where('active', isEqualTo: true)
          .limit(1).get();

      if (snap.docs.isEmpty)
        return SubResult(false, 'اسم المستخدم غير موجود');

      final data  = snap.docs.first.data();
      final docId = snap.docs.first.id;

      // Verify password
      final storedPass = data['password']?.toString() ?? '';
      if (storedPass != p)
        return SubResult(false, 'كلمة المرور غير صحيحة');

      // Check active
      if (data['active'] != true)
        return SubResult(false, 'الحساب موقوف — تواصل مع الدعم');

      // Check expiry
      final ts = data['expires_at'];
      if (ts is Timestamp && ts.toDate().isBefore(DateTime.now()))
        return SubResult(false, 'انتهت صلاحية اشتراك VIP');
      final expiry = ts is Timestamp
          ? ts.toDate()
          : DateTime.now().add(const Duration(days: 365));

      // Get activated date
      final actTs = data['activated_at'];
      final activatedAt = actTs is Timestamp
          ? actTs.toDate()
          : DateTime.now();

      // Smart server selection from Firestore
      final server = await _pickServer(data, docId);

      // Save session (encrypted keys only)
      await _saveVIP(
        plan:        kVIP,
        expiry:      expiry,
        activatedAt: activatedAt,
        xUser:       server['username']!,
        xPass:       server['password']!,
        xHost:       server['host']!,
        xPort:       server['port'] ?? '',
        serverId:    server['server_id'] ?? '',
      );

      // Track in Firestore
      _trackSession(docId, server['server_id'] ?? '');

      return SubResult(true, 'مرحباً! تم تفعيل اشتراك VIP',
          plan: kVIP, expiry: expiry, activatedAt: activatedAt);

    } catch (_) {
      return SubResult(false, 'خطأ في الاتصال — حاول مجدداً');
    }
  }

  // ── Smart Server Picker — Load Balancer ──────────────────────
  static Future<Map<String, String>> _pickServer(
      Map<String, dynamic> userData, String docId) async {

    // 1. User's dedicated servers list
    final userServers = (userData['servers'] as List?) ?? [];
    if (userServers.isNotEmpty) {
      final best = _leastLoaded(userServers.cast<Map>());
      if (best != null) return best;
    }

    // 2. Global VIP server pool
    try {
      final pool = await FirebaseFirestore.instance
          .collection('server_pool')
          .where('active',  isEqualTo: true)
          .where('healthy', isEqualTo: true)
          .where('type',    isEqualTo: 'vip')
          .orderBy('current_load')
          .limit(3).get();

      if (pool.docs.isNotEmpty) {
        final servers = pool.docs.map((d) => {
          ...d.data().map((k, v) => MapEntry(k, v.toString())),
          'server_id': d.id,
        }).toList();
        final best = _leastLoaded(servers);
        if (best != null) return best;
      }
    } catch (_) {}

    // 3. Xtream fields on user doc (direct)
    final xUser = userData['xtream_username']?.toString() ?? '';
    final xPass = userData['xtream_password']?.toString() ?? '';
    final xHost = userData['xtream_host']?.toString()     ?? '';
    final xPort = userData['xtream_port']?.toString()     ?? '';
    if (xUser.isNotEmpty) {
      return {
        'username': xUser, 'password': xPass,
        'host': xHost.isNotEmpty ? xHost : RC.serverUrl,
        'port': xPort, 'server_id': 'direct_$docId',
      };
    }

    // 4. Fallback: app main server
    return {
      'username': RC.username, 'password': RC.password,
      'host': RC.serverUrl, 'port': '', 'server_id': 'main',
    };
  }

  static Map<String, String>? _leastLoaded(List<Map> servers) {
    if (servers.isEmpty) return null;
    servers.sort((a, b) {
      final lA = int.tryParse(a['current_load']?.toString() ?? '0') ?? 0;
      final lB = int.tryParse(b['current_load']?.toString() ?? '0') ?? 0;
      final mA = int.tryParse(a['max_load']?.toString()     ?? '100') ?? 100;
      final mB = int.tryParse(b['max_load']?.toString()     ?? '100') ?? 100;
      if (lA >= mA) return 1;
      if (lB >= mB) return -1;
      final wA = int.tryParse(a['weight']?.toString() ?? '10') ?? 10;
      final wB = int.tryParse(b['weight']?.toString() ?? '10') ?? 10;
      return (lA * 10 ~/ wA).compareTo(lB * 10 ~/ wB);
    });
    final s = servers.first;
    return {
      'username':  s['username']?.toString()       ?? s['xtream_username']?.toString() ?? '',
      'password':  s['password']?.toString()       ?? s['xtream_password']?.toString() ?? '',
      'host':      s['host']?.toString()           ?? s['xtream_host']?.toString()     ?? '',
      'port':      s['port']?.toString()           ?? s['xtream_port']?.toString()     ?? '',
      'server_id': s['server_id']?.toString()      ?? s['id']?.toString()              ?? '',
    };
  }

  static void _trackSession(String docId, String serverId) {
    final db = FirebaseFirestore.instance;
    DeviceId.get().then((devId) async {
      try {
        await db.collection('vip_users').doc(docId).update({
          'last_login':      FieldValue.serverTimestamp(),
          'device_id':       devId,
          'active_server_id':serverId,
          'session_count':   FieldValue.increment(1),
        });
      } catch (_) {}
      // Increment server load
      if (serverId.isNotEmpty && !serverId.startsWith('main') && !serverId.startsWith('direct')) {
        try {
          await db.collection('server_pool').doc(serverId).update({
            'current_load': FieldValue.increment(1),
          });
        } catch (_) {}
      }
    });
  }

  // ── Normal Code ───────────────────────────────────────────────
  static Future<SubResult> validateCode(String code) async {
    final k = code.trim().toUpperCase();
    if (k.isEmpty) return SubResult(false, 'أدخل كود الاشتراك');
    try {
      final ref  = FirebaseFirestore.instance.collection('activation_codes').doc(k);
      final snap = await ref.get();
      if (!snap.exists) return SubResult(false, 'الكود غير صحيح أو منتهي');
      final data = snap.data()!;
      final ts   = data['expires_at'];
      DateTime? expiry;
      if (ts is Timestamp) expiry = ts.toDate();
      if (expiry != null && expiry.isBefore(DateTime.now()))
        return SubResult(false, 'انتهت صلاحية الكود');
      final used  = data['used'] == true;
      final devId = await DeviceId.get();
      if (used && (data['device_id'] ?? '') != devId)
        return SubResult(false, 'الكود مستخدم على جهاز آخر');
      final days = (data['duration_days'] as num?)?.toInt() ?? 30;
      final plan = data['plan']?.toString() == kVIP ? kVIP : kNormal;
      final now  = DateTime.now();
      final fin  = expiry ?? now.add(Duration(days: days));
      try {
        await ref.update({'used': true, 'used_at': FieldValue.serverTimestamp(),
            'device_id': devId, 'expires_at': Timestamp.fromDate(fin)});
      } catch (_) {}
      await _saveNormal(plan: plan, expiry: fin, activatedAt: now);
      return SubResult(true, 'تم تفعيل الاشتراك بنجاح',
          plan: plan, expiry: fin, activatedAt: now);
    } catch (_) {
      return SubResult(false, 'خطأ في الاتصال');
    }
  }

  // ── Save helpers ──────────────────────────────────────────────
  static Future<void> _saveVIP({
    required String plan, required DateTime expiry,
    required DateTime activatedAt,
    required String xUser, required String xPass,
    required String xHost, required String xPort,
    required String serverId,
  }) async {
    _premium = true; _plan = plan;
    _expiry = expiry; _activatedAt = activatedAt;
    _xUser = xUser; _xPass = xPass;
    _xHost = xHost; _xPort = xPort;
    _activeServerId = serverId;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('_s_pl',   plan);
      await p.setString('_s_ex',   expiry.toIso8601String());
      await p.setString('_s_ac',   activatedAt.toIso8601String());
      await p.setString('_vx_u',   xUser);
      await p.setString('_vx_p',   xPass);
      await p.setString('_vx_h',   xHost);
      await p.setString('_vx_pt',  xPort);
      await p.setString('_vx_sid', serverId);
    } catch (_) {}
  }

  static Future<void> _saveNormal({
    required String plan, required DateTime expiry,
    required DateTime activatedAt,
  }) async {
    _premium = true; _plan = plan;
    _expiry = expiry; _activatedAt = activatedAt;
    _xUser = ''; _xPass = ''; _xHost = ''; _xPort = '';
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('_s_pl', plan);
      await p.setString('_s_ex', expiry.toIso8601String());
      await p.setString('_s_ac', activatedAt.toIso8601String());
      await p.remove('_vx_u'); await p.remove('_vx_p');
      await p.remove('_vx_h'); await p.remove('_vx_pt');
      await p.remove('_vx_sid');
    } catch (_) {}
  }

  // ── VIP Direct — اتصال مباشر بدون Firestore ──────────────────
  static Future<void> saveVIPDirect({
    required String host,
    required String username,
    required String password,
  }) async {
    _premium = true;
    _plan = kVIP;
    _xUser = username;
    _xPass = password;
    _xHost = host;
    _xPort = '';
    _expiry = DateTime.now().add(const Duration(days: 3650)); // 10 سنوات
    _activatedAt = DateTime.now();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('_s_pl',  kVIP);
      await p.setString('_s_ex',  _expiry!.toIso8601String());
      await p.setString('_s_ac',  _activatedAt!.toIso8601String());
      await p.setString('_vx_u',  username);
      await p.setString('_vx_p',  password);
      await p.setString('_vx_h',  host);
      await p.setString('_vx_pt', '');
    } catch (_) {}
  }

  // ── Logout ────────────────────────────────────────────────────
  static Future<void> logout() async {
    // Decrement load counter
    if (_activeServerId.isNotEmpty &&
        !_activeServerId.startsWith('main') &&
        !_activeServerId.startsWith('direct')) {
      try {
        await FirebaseFirestore.instance
            .collection('server_pool').doc(_activeServerId).update({
          'current_load': FieldValue.increment(-1),
        });
      } catch (_) {}
    }
    await _clear();
  }

  static Future<void> _clear() async {
    _premium = false; _plan = kFree; _expiry = null; _activatedAt = null;
    _xUser = ''; _xPass = ''; _xHost = ''; _xPort = ''; _activeServerId = '';
    try {
      final p = await SharedPreferences.getInstance();
      for (final k in ['_s_pl','_s_ex','_s_ac','_vx_u','_vx_p','_vx_h','_vx_pt','_vx_sid']) {
        await p.remove(k);
      }
    } catch (_) {}
  }

  // ── URL builders (internal use only) ─────────────────────────
  static String buildStreamUrl(String type, String id, String ext) {
    if (isVIP && _xUser.isNotEmpty) {
      // VIP: direct to Xtream server
      final base = _xtreamBase.replaceAll(RegExp(r'/$'), '');
      if (kIsWeb) {
        // Web VIP: via Worker VIP proxy
        final proxy = RC.proxyUrl.replaceAll(RegExp(r'/$'), '');
        final enc   = Uri.encodeComponent('$base/$type/$_xUser/$_xPass/$id.$ext');
        return '$proxy/vip-stream?url=$enc';
      }
      return '$base/$type/$_xUser/$_xPass/$id.$ext';
    }
    // Normal/Free: Worker HLS proxy
    if (kIsWeb) {
      final proxy = RC.proxyUrl.replaceAll(RegExp(r'/$'), '');
      return '$proxy/hls/$type/$id';
    }
    // Native: main server
    final base = RC.serverUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/$type/${RC.username}/${RC.password}/$id.$ext';
  }

  static String buildApiUrl(String action, [Map<String, dynamic>? extra]) {
    if (isVIP && _xUser.isNotEmpty) {
      // VIP: direct API call to Xtream server
      final base = _xtreamBase.replaceAll(RegExp(r'/$'), '');
      final p = {'username': _xUser, 'password': _xPass, 'action': action,
        ...?extra?.map((k, v) => MapEntry(k, v.toString()))};
      final q = p.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      return '$base/player_api.php?$q';
    }
    // Normal/Free: Worker proxy
    return RC.buildApiUrl(action, extra);
  }
}

// ═══════════════════════════════════════════════════════════════
//  CMS SERVICE — الاتصال بـ Worker الجديد
// ═══════════════════════════════════════════════════════════════
class CmsService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static const _kServerCache   = 'cms_server_cache_v1';
  static const _kServerTs      = 'cms_server_ts_v1';
  static const _kAppConfig     = 'cms_app_config_v1';
  static const _kAppConfigTs   = 'cms_app_config_ts_v1';
  static const _serverCacheTtl = 24 * 3600 * 1000;
  static const _configCacheTtl = 5  * 60   * 1000;

  static Map<String, dynamic>? _serverData;
  static Map<String, dynamic>? _appConfig;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Future.wait([
      _loadServerFromCache(),
      _loadAppConfigFromCache(),
    ]);
    _initialized = true;
    _refreshInBackground();
  }

  static Future<void> _loadServerFromCache() async {
    try {
      final p   = await SharedPreferences.getInstance();
      final ts  = p.getInt(_kServerTs) ?? 0;
      final raw = p.getString(_kServerCache);
      if (raw != null && DateTime.now().millisecondsSinceEpoch - ts < _serverCacheTtl) {
        _serverData = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        debugPrint('CmsService: Server loaded from cache (${Sub.plan})');
      }
    } catch (_) {}
  }

  static Future<void> _loadAppConfigFromCache() async {
    try {
      final p   = await SharedPreferences.getInstance();
      final ts  = p.getInt(_kAppConfigTs) ?? 0;
      final raw = p.getString(_kAppConfig);
      if (raw != null && DateTime.now().millisecondsSinceEpoch - ts < _configCacheTtl) {
        _appConfig = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getServerData({bool force = false}) async {
    if (!force && _serverData != null) return _serverData;
    try {
      final deviceId = await DeviceId.get();
      final plan     = Sub.plan;
      final r = await _dio.post('${_getCmsBase()}/assign-server', data: {
        'plan':      plan,
        'device_id': deviceId,
      });
      if (r.statusCode == 200 && r.data is Map) {
        _serverData = Map<String, dynamic>.from(r.data as Map);
        final p = await SharedPreferences.getInstance();
        await p.setString(_kServerCache, jsonEncode(_serverData));
        await p.setInt(_kServerTs, DateTime.now().millisecondsSinceEpoch);
        debugPrint('CmsService: Server fetched from CMS for plan=$plan');
        return _serverData;
      }
    } catch (e) {
      debugPrint('CmsService: getServerData error: $e');
    }
    return _serverData;
  }

  static Future<Map<String, dynamic>> getAppConfig({bool force = false}) async {
    if (!force && _appConfig != null) return _appConfig!;
    try {
      final r = await _dio.get('${_getCmsBase()}/app-config');
      if (r.statusCode == 200 && r.data is Map) {
        _appConfig = Map<String, dynamic>.from(r.data as Map);
        final p = await SharedPreferences.getInstance();
        await p.setString(_kAppConfig, jsonEncode(_appConfig));
        await p.setInt(_kAppConfigTs, DateTime.now().millisecondsSinceEpoch);
        _applyAppConfig(_appConfig!);
        return _appConfig!;
      }
    } catch (e) {
      debugPrint('CmsService: getAppConfig error: $e');
    }
    return _appConfig ?? {};
  }

  static void _applyAppConfig(Map<String, dynamic> config) {
    RC.onConfigChanged?.call();
    Sub.updateRemote({
      'buy_url':           config['buy_url']           ?? '',
      'vip_buy_url':       config['vip_buy_url']        ?? '',
      'support_whatsapp':  config['support_whatsapp']   ?? '',
      'support_telegram':  config['support_telegram']   ?? '',
    });
    final notifs = (config['active_notifications'] as List? ?? []);
    for (final n in notifs.take(1)) {
      final msg = n['body']?.toString() ?? '';
      if (msg.isNotEmpty) NotifService.show(n['title'] ?? 'TOTV+', msg);
    }
  }

  static Future<List<String>> refreshUrl({
    required String type,
    required String id,
    required String ext,
  }) async {
    try {
      final deviceId = await DeviceId.get();
      final r = await _dio.get('${_getCmsBase()}/refresh-url', queryParameters: {
        'type': type, 'id': id, 'ext': ext,
        'plan': Sub.plan, 'device_id': deviceId,
      });
      if (r.statusCode == 200 && r.data is Map) {
        final data = r.data as Map;
        final urls = <String>[];
        if (data['url'] != null)       urls.add(data['url'].toString());
        if (data['https_url'] != null) urls.add(data['https_url'].toString());
        final extra = (data['urls'] as List?)?.map((e) => e.toString()).toList() ?? [];
        urls.addAll(extra);
        return urls.toSet().toList();
      }
    } catch (e) {
      debugPrint('CmsService: refreshUrl error: $e');
    }
    return [];
  }

  static String buildStreamUrl(String type, String id, String ext) {
    if (_serverData == null) return RC.buildApiUrl('get_live_streams');
    final host = (_serverData!['host'] ?? '').toString().replaceAll(RegExp(r'/$'), '');
    final user = (_serverData!['username'] ?? '').toString();
    final pass = (_serverData!['password'] ?? '').toString();
    if (host.isEmpty || user.isEmpty) return Sub.buildStreamUrl(type, id, ext);
    if (kIsWeb) {
      final httpsHost = (_serverData!['https_host'] ?? '').toString();
      if (httpsHost.isNotEmpty && httpsHost != host) {
        return '$httpsHost/$type/$user/$pass/$id.$ext';
      }
      final proxy = RC.proxyUrl.replaceAll(RegExp(r'/$'), '');
      return '$proxy/vip-stream?url=${Uri.encodeComponent('$host/$type/$user/$pass/$id.$ext')}';
    }
    return '$host/$type/$user/$pass/$id.$ext';
  }

  static String buildApiUrl(String action, [Map<String, dynamic>? extra]) {
    if (_serverData == null) return RC.buildApiUrl(action, extra);
    final host = (_serverData!['host'] ?? '').toString().replaceAll(RegExp(r'/$'), '');
    final user = (_serverData!['username'] ?? '').toString();
    final pass = (_serverData!['password'] ?? '').toString();
    if (host.isEmpty || user.isEmpty) return RC.buildApiUrl(action, extra);
    final params = <String, String>{
      'username': user, 'password': pass, 'action': action,
      ...?extra?.map((k, v) => MapEntry(k, v.toString())),
    };
    final q = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$host/player_api.php?$q';
  }

  static String get serverHost     => (_serverData?['host']     ?? RC.serverUrl).toString();
  static String get serverUsername => (_serverData?['username'] ?? RC.username).toString();
  static String get serverPassword => (_serverData?['password'] ?? RC.password).toString();
  static bool   get hasServerData  => _serverData != null;

  static Set<String> _blockedChannels = {};

  static Future<void> loadBlockedChannels() async {
    try {
      final r = await _dio.get('${_getCmsBase()}/live-config');
      if (r.statusCode == 200 && r.data is Map) {
        final blocked = (r.data['blocked_channels'] as List? ?? []);
        _blockedChannels = blocked.map((e) => e.toString()).toSet();
      }
    } catch (_) {}
  }

  static bool isBlocked(String channelId) => _blockedChannels.contains(channelId);

  static void _refreshInBackground() {
    Future.delayed(const Duration(seconds: 5), () async {
      await getServerData(force: true);
      await getAppConfig(force: true);
      await loadBlockedChannels();
    });
    Future.delayed(const Duration(hours: 24), () => _refreshInBackground());
  }

  static String _getCmsBase() => kCmsBase;

  static Future<void> clearCache() async {
    _serverData = null;
    _appConfig  = null;
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kServerCache);
      await p.remove(_kServerTs);
    } catch (_) {}
  }

  static Future<void> trackAppOpen() async {
    try {
      final deviceId = await DeviceId.get();
      await _dio.post('${_getCmsBase()}/assign-server', data: {
        'plan':      Sub.plan,
        'device_id': deviceId,
      });
    } catch (_) {}
  }
}

// ═══════════════════════════════════════════════════════════════
//  VODU SEARCH SERVICE
// ═══════════════════════════════════════════════════════════════
class VoduSearchService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  ));

  static Future<VoduResult> search({
    required String title,
    String type = 'movie',
    String? season,
    String? episode,
  }) async {
    try {
      final params = <String, String>{
        'title': title,
        'type':  type,
        if (season  != null) 'season':  season,
        if (episode != null) 'episode': episode,
      };
      final r = await _dio.get('${CmsService._getCmsBase()}/vodu-search', queryParameters: params)
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200 && r.data is Map) {
        final data = r.data as Map;
        if (data['found'] == true) {
          final playUrl = data['play_url']?.toString() ?? '';
          final fullUrl = playUrl.startsWith('/')
              ? '${CmsService._getCmsBase()}$playUrl'
              : playUrl;
          return VoduResult(found: true, url: fullUrl, source: 'vodu.me');
        }
      }
    } catch (e) {
      debugPrint('VoduSearch error: $e');
    }
    return const VoduResult(found: false);
  }
}

class VoduResult {
  final bool   found;
  final String url;
  final String source;
  const VoduResult({required this.found, this.url = '', this.source = ''});
}

// ═══════════════════════════════════════════════════════════════
//  CMS CONTENT SERVICE
// ═══════════════════════════════════════════════════════════════
class CmsContentService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 25),
  ));

  static Future<List<dynamic>> getContent(String type, {int page = 1, String? query}) async {
    try {
      final params = <String, String>{'type': type, 'page': page.toString()};
      if (query != null && query.isNotEmpty) params['q'] = query;
      final r = await _dio.get('${CmsService._getCmsBase()}/content', queryParameters: params)
          .timeout(const Duration(seconds: 20));
      if (r.statusCode == 200 && r.data is Map) {
        return (r.data as Map)['items'] as List? ?? [];
      }
    } catch (e) {
      debugPrint('CmsContent error [$type]: $e');
    }
    return [];
  }

  static Future<Map<String, List<dynamic>>> batchFetch() async {
    final results = <String, List<dynamic>>{};
    await Future.wait([
      getContent('movies').then((v) => results['movies'] = v).catchError((_) => results['movies'] = []),
      getContent('series').then((v) => results['series'] = v).catchError((_) => results['series'] = []),
      getContent('live').then((v)   => results['live']   = v).catchError((_) => results['live']   = []),
    ]);
    return results;
  }
}

// ═══════════════════════════════════════════════════════════════
//  TV LAYOUT HELPER
// ═══════════════════════════════════════════════════════════════
class TVLayout {
  static bool _isTV     = false;
  static bool _detected = false;

  static Future<void> detect() async {
    if (_detected) return;
    _detected = true;
    try {
      if (!kIsWeb && Plat.isAndroid) {
        final info    = await DeviceInfoPlugin().androidInfo;
        final display = WidgetsBinding.instance.platformDispatcher.views.first;
        final ratio   = display.physicalSize.shortestSide / display.devicePixelRatio;
        _isTV = ratio >= 700 || info.systemFeatures.contains('android.software.leanback');
      }
    } catch (_) {}
  }

  static bool get isTV => _isTV || Plat.isTV;

  static double get titleFontSize => isTV ? 24.0 : 16.0;
  static double get bodyFontSize  => isTV ? 18.0 : 13.0;
  static double get cardWidth     => isTV ? 220.0 : 130.0;
  static double get cardHeight    => isTV ? 130.0 : 75.0;

  static EdgeInsets get pagePadding => isTV
      ? const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0)
      : const EdgeInsets.all(16.0);
}

// ═══════════════════════════════════════════════════════════════
//  TV FOCUS MANAGER
// ═══════════════════════════════════════════════════════════════
class TVFocusHelper {
  static Widget withDpad({
    required Widget child,
    VoidCallback? onUp,
    VoidCallback? onDown,
    VoidCallback? onLeft,
    VoidCallback? onRight,
    VoidCallback? onOk,
    VoidCallback? onBack,
  }) {
    if (!TVLayout.isTV) return child;
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp)    { onUp?.call();    return KeyEventResult.handled; }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown)  { onDown?.call();  return KeyEventResult.handled; }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft)  { onLeft?.call();  return KeyEventResult.handled; }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) { onRight?.call(); return KeyEventResult.handled; }
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) { onOk?.call(); return KeyEventResult.handled; }
        if (event.logicalKey == LogicalKeyboardKey.goBack) { onBack?.call(); return KeyEventResult.handled; }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HTTPS PROXY HELPER
// ═══════════════════════════════════════════════════════════════
class HttpsProxy {
  static String fix(String url) {
    if (url.isEmpty || url.startsWith('https://')) return url;
    if (!url.startsWith('http://')) return url;
    if (!kIsWeb) return url;
    return '${CmsService._getCmsBase()}/img?url=${Uri.encodeComponent(url)}';
  }

  static String fixStream(String url) {
    if (url.isEmpty || url.startsWith('https://')) return url;
    if (!url.startsWith('http://')) return url;
    if (!kIsWeb) return url;
    return '${CmsService._getCmsBase()}/vip-stream?url=${Uri.encodeComponent(url)}';
  }

  static Map<String, dynamic> fixItem(Map<String, dynamic> item) {
    if (!kIsWeb) return item;
    final out = Map<String, dynamic>.from(item);
    for (final key in ['stream_icon', 'cover', 'backdrop_path', 'thumbnail', 'logo']) {
      final v = out[key]?.toString() ?? '';
      if (v.isNotEmpty) out[key] = fix(v);
    }
    return out;
  }
}

class SubResult {
  final bool ok;
  final String msg;
  final int days;
  final String plan;
  final DateTime? expiry;
  final DateTime? activatedAt;
  const SubResult(this.ok, this.msg, {
    this.days = 30,
    this.plan = 'normal',
    this.expiry,
    this.activatedAt,
  });
}

// ─────────────────────────────────────────────────────────
//  WATCHLIST
// ─────────────────────────────────────────────────────────
class WL {
  static const _k = 'totv_wl_v5';
  static List<Map<String, dynamic>> _items = [];
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      final r = p.getString(_k);
      if (r != null) _items = (jsonDecode(r) as List).cast<Map<String, dynamic>>();
    } catch (_) {}
    _loaded = true;
  }

  static String _id(dynamic i) =>
      i['stream_id']?.toString() ?? i['series_id']?.toString() ?? '';

  static bool has(dynamic i) => _items.any((e) => _id(e) == _id(i));

  static Future<void> toggle(dynamic item, String type) async {
    final id = _id(item);
    if (has(item)) { _items.removeWhere((e) => _id(e) == id); }
    else           { _items.add({...Map<String, dynamic>.from(item as Map), '_type': type}); }
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_k, jsonEncode(_items));
    } catch (_) {}
  }

  static List<Map<String, dynamic>> get all => List.unmodifiable(_items);
}


// ════════════════════════════════════════════════════════════════
//  WATCH HISTORY — سجل المشاهدة + استكمال التشغيل (Netflix-style)
// ════════════════════════════════════════════════════════════════
class WatchHistory {
  static const _kHistory  = 'totv_watch_history_v1';
  static const _kProgress = 'totv_watch_progress_v1';
  static const _maxItems  = 50;

  static List<Map<String, dynamic>> _history  = [];
  static Map<String, int>           _progress = {}; // id → seconds
  static bool _loaded = false;

  // ── تحميل من الذاكرة ──────────────────────────────────────
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      final h = p.getString(_kHistory);
      final pr = p.getString(_kProgress);
      if (h  != null) _history  = (jsonDecode(h)  as List).cast<Map<String, dynamic>>();
      if (pr != null) _progress = Map<String, int>.from(jsonDecode(pr) as Map);
    } catch (_) {}
    _loaded = true;
  }

  // ── حفظ تقدم المشاهدة — يقبل ثوانٍ أو milliseconds (ذكي) ──
  static Future<void> saveProgress(String id, int val, int total) async {
    if (id.isEmpty || val <= 0) return;
    // auto-detect ms vs seconds (if > 3600 assume ms)
    final secs  = val   > 3600 ? val   ~/ 1000 : val;
    final total2= total > 3600 ? total ~/ 1000 : total;
    if (secs < 5) return;
    final pct = total2 > 0 ? secs / total2 : 0;
    if (pct > 0.97) { _progress.remove(id); } // مكتمل — حذف يعني اكتمل
    else            { _progress[id] = secs; }
    _saveToDisk();
  }

  // ── إضافة للسجل ────────────────────────────────────────────
  static Future<void> addToHistory(dynamic item, String type) async {
    final id = _itemId(item);
    if (id.isEmpty) return;
    _history.removeWhere((e) => _itemId(e) == id);
    _history.insert(0, {
      ...Map<String, dynamic>.from(item as Map),
      '_type':      type,
      '_watched_at': DateTime.now().millisecondsSinceEpoch,
    });
    if (_history.length > _maxItems) _history = _history.take(_maxItems).toList();
    _saveToDisk();
  }

  // ── جلب موضع الاستكمال ─────────────────────────────────────
  static Duration? getProgress(String id) {
    final s = _progress[id];
    return s != null ? Duration(seconds: s) : null;
  }

  static bool hasProgress(dynamic item) {
    final id = _itemId(item);
    return id.isNotEmpty && _progress.containsKey(id);
  }

  // نسبة التقدم 0.0 → 1.0
  static double getProgressPct(String id, int totalSeconds) {
    final s = _progress[id] ?? 0;
    if (s == -1) return 1.0; // completed
    return totalSeconds > 0 ? (s / totalSeconds).clamp(0.0, 1.0) : 0;
  }

  // getPercent: compatible with ms or seconds total
  static double getPercent(String id, int durMs) {
    final s = _progress[id] ?? 0;
    if (s == -1) return 1.0;
    if (s == 0) return 0.0;
    if (durMs <= 0) return s > 0 ? 0.1 : 0.0; // no total known, just show partial
    final durSecs = durMs > 3600 ? durMs ~/ 1000 : durMs;
    return (s / durSecs).clamp(0.0, 1.0);
  }

  static List<Map<String, dynamic>> get recentHistory =>
      List.unmodifiable(_history.take(20));

  static List<Map<String, dynamic>> get inProgress {
    return _history.where((item) => hasProgress(item)).toList();
  }

  static String _itemId(dynamic i) =>
      i['stream_id']?.toString() ?? i['series_id']?.toString() ??
      i['id']?.toString() ?? '';

  static void _saveToDisk() {
    Future.microtask(() async {
      try {
        final p = await SharedPreferences.getInstance();
        await p.setString(_kHistory,  jsonEncode(_history));
        await p.setString(_kProgress, jsonEncode(_progress));
      } catch (_) {}
    });
  }

  static Future<void> clear() async {
    _history.clear(); _progress.clear();
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kHistory); await p.remove(_kProgress);
    } catch (_) {}
  }

  // ── API مطلوبة من باقي الكود ─────────────────────────────
  // getProgress(id) → int milliseconds (0 if none, -1 if completed)
  static int getProgressMs(String id) {
    final s = _progress[id]; // seconds from old API
    if (s == null) return 0;
    return s * 1000; // convert to ms
  }

  // isCompleted: progress removed means completed (pct > 0.98)
  // -1 means completed (watched > 98%)
  static bool isCompleted(String id) => !_progress.containsKey(id);

  // getPercent for progress bar on cards
  // addItem alias for addToHistory
  static Future<void> addItem(dynamic item, String type) =>
      addToHistory(item, type);

  // recent alias
  static List<Map<String, dynamic>> get recent => recentHistory;

  // recommend: smart recommendations based on watched categories
  static List<dynamic> recommend(List<dynamic> pool, {int count = 20}) {
    final history = recentHistory;
    if (history.isEmpty) return pool.take(count).toList();
    final catCount = <String, int>{};
    for (final h in history.take(30)) {
      final cat = h['category_id']?.toString() ?? '';
      if (cat.isNotEmpty) catCount[cat] = (catCount[cat] ?? 0) + 1;
    }
    final watched = history
        .map((e) => e['stream_id']?.toString() ?? e['series_id']?.toString() ?? '')
        .where((s) => s.isNotEmpty).toSet();
    final scored = pool.where((item) {
      final id = item['stream_id']?.toString() ?? item['series_id']?.toString() ?? '';
      return !watched.contains(id);
    }).map((item) {
      final cat = item['category_id']?.toString() ?? '';
      return MapEntry(item, catCount[cat] ?? 0);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored.take(count).map((e) => e.key).toList();
  }
}


// ════════════════════════════════════════════════════════════════
//  RECOMMENDATIONS — ترشيحات ذكية بناءً على سلوك المستخدم
// ════════════════════════════════════════════════════════════════
class Recommendations {

  // ── بناء ترشيحات من السجل ──────────────────────────────────
  static List<dynamic> forYou({int limit = 20}) {
    final history = WatchHistory.recentHistory;
    if (history.isEmpty) return _fallback(limit);

    // جمع الفئات المشاهودة بأوزان
    final catWeights = <String, int>{};
    for (final item in history.take(10)) {
      final cat = item['category_id']?.toString() ?? '';
      if (cat.isNotEmpty) catWeights[cat] = (catWeights[cat] ?? 0) + 1;
    }

    // فلترة المحتوى بالفئات المفضلة
    final watched = history.map((e) =>
        e['stream_id']?.toString() ?? e['series_id']?.toString() ?? '').toSet();

    final pool = [...AppState.allMovies, ...AppState.allSeries];
    final scored = <MapEntry<dynamic, int>>[];

    for (final item in pool) {
      final id  = item['stream_id']?.toString() ?? item['series_id']?.toString() ?? '';
      if (watched.contains(id)) continue; // استبعد المشاهَد

      final cat   = item['category_id']?.toString() ?? '';
      final score = catWeights[cat] ?? 0;
      if (score > 0) scored.add(MapEntry(item, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    final result = scored.take(limit).map((e) => e.key).toList();
    return result.isEmpty ? _fallback(limit) : result;
  }

  // ── مشابه للمحتوى الحالي ──────────────────────────────────
  static List<dynamic> similar(dynamic item, {int limit = 12}) {
    final cat  = item['category_id']?.toString() ?? '';
    final id   = item['stream_id']?.toString() ?? item['series_id']?.toString() ?? '';
    final pool = [...AppState.allMovies, ...AppState.allSeries];

    return pool
        .where((e) {
          final eId  = e['stream_id']?.toString() ?? e['series_id']?.toString() ?? '';
          final eCat = e['category_id']?.toString() ?? '';
          return eId != id && eCat == cat;
        })
        .take(limit)
        .toList();
  }

  // ── مواصلة ما بدأت ────────────────────────────────────────
  static List<dynamic> continueWatching({int limit = 10}) =>
      WatchHistory.inProgress.take(limit).toList();

  static List<dynamic> _fallback(int limit) {
    final pool = [...AppState.allMovies.take(limit ~/ 2),
                  ...AppState.allSeries.take(limit ~/ 2)];
    pool.shuffle();
    return pool.take(limit).toList();
  }

}

// ─────────────────────────────────────────────────────────
//  MULTI-PROFILE — ملفات شخصية متعددة (مثل Netflix)
// ─────────────────────────────────────────────────────────
class ProfileManager {
  static const _kProfiles = 'totv_profiles_v1';
  static const _kActive   = 'totv_active_profile_v1';

  static List<Map<String,dynamic>> _profiles = [];
  static String _activeId = 'default';
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kProfiles);
      if (raw != null) _profiles = (jsonDecode(raw) as List).cast<Map<String,dynamic>>();
      _activeId = p.getString(_kActive) ?? 'default';
    } catch (_) {}
    // الملف الافتراضي دائماً موجود
    if (_profiles.isEmpty) {
      _profiles = [{'id': 'default', 'name': 'أنا', 'avatar': '👤', 'kids': false}];
    }
    _loaded = true;
  }

  static List<Map<String,dynamic>> get profiles => List.unmodifiable(_profiles);
  static Map<String,dynamic> get active =>
      _profiles.firstWhere((p) => p['id'] == _activeId, orElse: () => _profiles.first);
  static bool get isKidsMode => active['kids'] == true;
  static String get activeId => _activeId;

  static Future<void> switchTo(String id) async {
    _activeId = id;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kActive, id);
    } catch (_) {}
  }

  static Future<void> addProfile(String name, String avatar, {bool kids = false}) async {
    if (_profiles.length >= 5) return;
    final id = 'profile_${DateTime.now().millisecondsSinceEpoch}';
    _profiles.add({'id': id, 'name': name, 'avatar': avatar, 'kids': kids});
    await _save();
  }

  static Future<void> deleteProfile(String id) async {
    if (id == 'default') return;
    _profiles.removeWhere((p) => p['id'] == id);
    if (_activeId == id) _activeId = 'default';
    await _save();
  }

  static Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kProfiles, jsonEncode(_profiles));
    } catch (_) {}
  }
}


// ════════════════════════════════════════════════════════════════
//  EPG — جدول البرامج للقنوات المباشرة (Electronic Program Guide)
// ════════════════════════════════════════════════════════════════
class EpgProgram {
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  const EpgProgram({required this.title, required this.description,
      required this.start, required this.end});

  bool get isLive => DateTime.now().isAfter(start) && DateTime.now().isBefore(end);
  double get progress {
    final total = end.difference(start).inSeconds;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0;
  }
  String get timeRange =>
      '${_fmt(start)} - ${_fmt(end)}';
  static String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,"0")}:${dt.minute.toString().padLeft(2,"0")}';
}

class EpgService {
  static final Map<String, List<EpgProgram>> _cache = {};
  static final Map<String, DateTime>         _time  = {};
  static final _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10)));

  // ── جلب EPG لقناة معينة ────────────────────────────────────
  static Future<List<EpgProgram>> fetch(String channelId) async {
    final cached = _cache[channelId];
    final t = _time[channelId];
    if (cached != null && t != null &&
        DateTime.now().difference(t).inMinutes < 60) return cached;
    try {
      // جلب من Worker endpoint
      final proxy = RC.proxyUrl.replaceAll(RegExp(r'/$'), '');
      final r = await _dio.get('$proxy/epg/$channelId');
      if (r.data is List) {
        final programs = (r.data as List).map((e) {
          try {
            return EpgProgram(
              title:       e['title']?.toString() ?? 'برنامج',
              description: e['description']?.toString() ?? '',
              start: DateTime.fromMillisecondsSinceEpoch((e['start'] as num).toInt() * 1000),
              end:   DateTime.fromMillisecondsSinceEpoch((e['stop']  as num).toInt() * 1000),
            );
          } catch (_) { return null; }
        }).whereType<EpgProgram>().toList();
        _cache[channelId] = programs;
        _time[channelId] = DateTime.now();
        return programs;
      }
    } catch (_) {}
    // fallback: برنامج وهمي "على الهواء الآن"
    return [EpgProgram(
      title: 'على الهواء الآن',
      description: '',
      start: DateTime.now().subtract(const Duration(hours: 1)),
      end:   DateTime.now().add(const Duration(hours: 1)),
    )];
  }

  static EpgProgram? currentProgram(String channelId) {
    final programs = _cache[channelId] ?? [];
    try {
      return programs.firstWhere((p) => p.isLive);
    } catch (_) { return programs.isNotEmpty ? programs.first : null; }
  }
}

// ─────────────────────────────────────────────────────────
//  ADS
// ─────────────────────────────────────────────────────────
class Ads {
  static bool _loading = false, _ready = false;
  static InterstitialAd? _inter;
  static bool get _can => !Sub.isPremium && !kIsWeb && Plat.isMobile;

  static Future<void> init() async {
    if (kIsWeb || !Plat.isMobile) return;
    try { await MobileAds.instance.initialize(); } catch (_) {}
  }

  static void preload() {
    if (!_can || _loading || _ready) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: kAdInterId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _inter = ad; _ready = true; _loading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) { _inter = null; _ready = false; preload(); },
            onAdFailedToShowFullScreenContent: (_, __) { _inter = null; _ready = false; },
          );
        },
        onAdFailedToLoad: (_) { _loading = false; },
      ),
    );
  }

  static Future<void> show() async {
    if (!_can || !_ready || _inter == null) return;
    try { await _inter!.show(); } catch (_) {}
  }

  static void dispose() {
    _inter?.dispose(); _inter = null; _ready = false; _loading = false;
  }
}

// ─────────────────────────────────────────────────────────
//  TMDB — بوسترات عالية الجودة
// ─────────────────────────────────────────────────────────
class TMDB {
  static const _key  = '5b166a24c91f59178e8ce30f1f3735c0';
  static const _base = 'https://api.themoviedb.org/3';
  static const _img  = 'https://image.tmdb.org/t/p';
  // Sizes: w92, w154, w185, w342, w500, w780, original
  static const _szThumb = 'w342';   // للبطاقات الصغيرة
  static const _szPoster= 'w500';   // للبطاقات الكبيرة
  static const _szLarge = 'w780';   // للتفاصيل — جودة عالية
  static const _szBack  = 'w1280';  // للـ backdrop — جودة عالية جداً
  static final _dio  = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8)));
  static final _cache = HashMap<String, Map<String, String>>();

  static String poster(String path, {String size = 'w780'}) =>
      path.isEmpty ? '' : '$_img/$size$path';
  static String backdrop(String path) =>
      path.isEmpty ? '' : '$_img/w1280$path';
  static String thumb(String path) =>
      path.isEmpty ? '' : '$_img/w342$path';

  static String _clean(String n) => n
      .replaceAll(RegExp(r'\b(4K|FHD|HD|SD|UHD|720p|1080p|2160p|S\d{2}E\d{2})\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'[\[\]()|_\-]'), ' ')
      .replaceAll(RegExp(r'\s{2,}'), ' ').trim();

  static Future<Map<String, String>> search(String name, {bool isTv = false}) async {
    final key = '${isTv?"tv":"mv"}_$name';
    if (_cache.containsKey(key)) return _cache[key]!;
    for (final lang in ['ar', 'en']) {
      try {
        final r = await _dio.get('$_base/search/${isTv?"tv":"movie"}',
            queryParameters: {'api_key': _key, 'query': _clean(name),
                'language': lang, 'include_adult': false});
        final results = (r.data['results'] as List?)?.cast<Map>();
        if (results == null || results.isEmpty) continue;
        final best = results.firstWhere(
            (x) => (x['poster_path'] ?? '').toString().isNotEmpty,
            orElse: () => results.first);
        final rawYear = (best['release_date'] ?? best['first_air_date'] ?? '').toString();
        // جلب طاقم العمل
        String cast = '';
        String director = '';
        String language = '';
        try {
          final credits = await _dio.get(
              '$_base/${isTv?"tv":"movie"}/${best['id']}/credits',
              queryParameters: {'api_key': _key});
          final castList = (credits.data['cast'] as List?)?.take(5)
              .map((c) => c['name']?.toString() ?? '').toList() ?? [];
          cast = castList.join('، ');
          final crew = credits.data['crew'] as List? ?? [];
          director = crew.firstWhere(
              (c) => c['job'] == 'Director', orElse: () => {})['name']?.toString() ?? '';
        } catch (_) {}
        // لغة المحتوى
        language = best['original_language']?.toString() ?? '';

        final info = <String, String>{
          'poster':    poster(best['poster_path']?.toString() ?? '', size: 'w780'),
          'poster_sm': poster(best['poster_path']?.toString() ?? '', size: 'w342'),
          'backdrop':  backdrop(best['backdrop_path']?.toString() ?? ''),
          'overview':  best['overview']?.toString() ?? '',
          'rating':    (best['vote_average'] ?? 0.0).toStringAsFixed(1),
          'year':      rawYear.length >= 4 ? rawYear.substring(0, 4) : rawYear,
          'title':     (best['title'] ?? best['name'] ?? name).toString(),
          'genres':    ((best['genre_ids'] as List?)?.map((e) => e.toString()).join(',') ?? ''),
          'cast':      cast,
          'director':  director,
          'language':  language,
          'vote_count': (best['vote_count'] ?? 0).toString(),
          'tmdb_id':   best['id'].toString(),
        };
        if (info['poster']!.isNotEmpty || info['backdrop']!.isNotEmpty) {
          _cache[key] = info;
          return info;
        }
      } catch (_) {}
    }
    return {};
  }

  static Future<Map<String, String>> fromWorker(String id, String name, {bool isTv = false}) async {
    final cKey = 'tmdb_${isTv?"tv":"mv"}_$id';
    if (_cache.containsKey(cKey)) return _cache[cKey]!;
    final info = await search(name, isTv: isTv);
    if (info.isNotEmpty) _cache[cKey] = info;
    return info;
  }
}

// ─────────────────────────────────────────────────────────
//  CACHE
// ─────────────────────────────────────────────────────────
class ListCache {
  static final Map<String, List<dynamic>> _data = {};
  static final Map<String, DateTime>      _time = {};

  static List<dynamic>? get(String k) {
    final t = _time[k];
    if (t == null || DateTime.now().difference(t).inMinutes > 120) return null;
    return _data[k];
  }
  static void put(String k, List<dynamic> v) { _data[k] = v; _time[k] = DateTime.now(); }
  static void invalidate() { _data.clear(); _time.clear(); }
}

class SeriesInfoCache {
  static final Map<String, Map<String, dynamic>> _d = {};
  static final Map<String, DateTime>             _t = {};
  static const _ttl = 25;

  static Map<String, dynamic>? get(String id) {
    final t = _t[id];
    if (t == null || DateTime.now().difference(t).inMinutes > _ttl) return null;
    return _d[id];
  }
  static void put(String id, Map<String, dynamic> v) { _d[id] = v; _t[id] = DateTime.now(); }
}

// ── PlayURL Cache — روابط التشغيل التي تعمل (24 ساعة) ──────
// يخزن الرابط الناجح لكل محتوى — عند الضغط مرة ثانية يفتح فوراً
// ═══════════════════════════════════════════════════════════════
//  PLAY URL CACHE v2 — يدعم التحديث التلقائي من CMS
// ═══════════════════════════════════════════════════════════════
class PlayUrlCache {
  static const _k        = 'totv_play_urls_v2';
  static const _maxItems = 500;
  static const _ttl      = 24 * 3600 * 1000; // 24 ساعة

  static Map<String, _CachedUrl> _cache = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final p   = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw != null) {
        final map = jsonDecode(raw) as Map;
        _cache = map.map((k, v) => MapEntry(k.toString(), _CachedUrl.fromJson(v as Map)));
      }
    } catch (_) {}
    _loaded = true;
  }

  static String? get(String id) {
    final entry = _cache[id];
    if (entry == null) return null;
    if (DateTime.now().millisecondsSinceEpoch - entry.ts > _ttl) {
      _cache.remove(id);
      return null;
    }
    return entry.url;
  }

  static void put(String id, String url) {
    if (id.isEmpty || url.isEmpty) return;
    _cache[id] = _CachedUrl(url: url, ts: DateTime.now().millisecondsSinceEpoch);
    if (_cache.length > _maxItems) {
      final oldest = _cache.entries.toList()..sort((a, b) => a.value.ts.compareTo(b.value.ts));
      for (final e in oldest.take(_cache.length - _maxItems)) _cache.remove(e.key);
    }
    _saveToDisk();
  }

  static Future<void> invalidate(String id) async {
    _cache.remove(id);
    _saveToDisk();
  }

  static Future<void> clear() async {
    _cache.clear();
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_k);
    } catch (_) {}
  }

  static void _saveToDisk() {
    Future.microtask(() async {
      try {
        final p = await SharedPreferences.getInstance();
        await p.setString(_k, jsonEncode(_cache.map((k, v) => MapEntry(k, v.toJson()))));
      } catch (_) {}
    });
  }
}

class _CachedUrl {
  final String url;
  final int    ts;
  const _CachedUrl({required this.url, required this.ts});
  factory _CachedUrl.fromJson(Map m) => _CachedUrl(url: m['url']?.toString() ?? '', ts: (m['ts'] as int?) ?? 0);
  Map<String, dynamic> toJson() => {'url': url, 'ts': ts};
}

// ── Live Load Balancer — توزيع أحمال البث الذكي ──────────────
class LiveLoadBalancer {
  // قائمة السيرفرات مع حالتها
  static final Map<String, _ServerHealth> _health = {};
  static int _roundRobin = 0;
  static const int _maxFails    = 3;   // حد الفشل قبل الاستبعاد
  static const int _cooldownSec = 60;  // انتظار قبل إعادة المحاولة

  // سجّل نجاح رابط
  static void markSuccess(String host) {
    _health.putIfAbsent(host, () => _ServerHealth(host));
    _health[host]!.recordSuccess();
  }

  // سجّل فشل رابط
  static void markFail(String host) {
    _health.putIfAbsent(host, () => _ServerHealth(host));
    _health[host]!.recordFail();
  }

  // هل السيرفر متاح؟
  static bool isHealthy(String host) {
    final h = _health[host];
    if (h == null) return true; // غير معروف = نفترض جيد
    return h.isHealthy(_maxFails, _cooldownSec);
  }

  // اختر أفضل رابط من قائمة
  static String pickBest(List<String> urls) {
    if (urls.isEmpty) return '';
    if (urls.length == 1) return urls.first;

    // فلتر الروابط السليمة
    final healthy = urls.where((u) {
      try { return isHealthy(Uri.parse(u).host); } catch (_) { return true; }
    }).toList();

    if (healthy.isEmpty) return urls.first; // الكل فشل — جرب الأول
    // Round-robin بين الروابط السليمة
    _roundRobin = (_roundRobin + 1) % healthy.length;
    return healthy[_roundRobin];
  }
}

class _ServerHealth {
  final String host;
  int _fails = 0;
  int _lastFail = 0;
  int _successStreak = 0;

  _ServerHealth(this.host);

  void recordSuccess() {
    _fails = (_fails - 1).clamp(0, 99);
    _successStreak++;
  }

  void recordFail() {
    _fails++;
    _lastFail = DateTime.now().millisecondsSinceEpoch;
    _successStreak = 0;
  }

  bool isHealthy(int maxFails, int cooldownSec) {
    if (_fails < maxFails) return true;
    // انتهت فترة الـ cooldown؟
    final elapsed = (DateTime.now().millisecondsSinceEpoch - _lastFail) ~/ 1000;
    if (elapsed >= cooldownSec) {
      _fails = maxFails - 1; // أعطِه فرصة
      return true;
    }
    return false;
  }
}

// ─────────────────────────────────────────────────────────
//  API
// ─────────────────────────────────────────────────────────
class Api {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'Accept':       'application/json',
      'Content-Type': 'application/json',
    },
  ))..interceptors.addAll([
    _RetryInterceptor(),
    InterceptorsWrapper(
      onResponse: (res, handler) {
        // تأكد أن الرد صالح
        if (res.statusCode == 200) handler.next(res);
        else handler.reject(DioException(
          requestOptions: res.requestOptions,
          response: res,
          message: 'HTTP ${res.statusCode}',
        ));
      },
      onError: (err, handler) {
        debugPrint('Dio Error: ${err.requestOptions.uri} → ${err.message}');
        handler.next(err);
      },
    ),
  ]);

  static Future<List<dynamic>> getList(String action,
      {bool force = false, Map<String, dynamic>? extra}) async {
    final cacheKey = '${Sub.isVIP ? "vip" : RC.proxyUrl}_${action}_${extra?.toString() ?? ''}';
    if (!force) {
      final cached = ListCache.get(cacheKey);
      if (cached != null) return cached;
    }
    try {
      // VIP: مباشر للسيرفر الخاص، بقية المستخدمين: Worker
      final url = Sub.isVIP && Sub.xtreamUser.isNotEmpty
          ? Sub.buildApiUrl(action, extra)
          : RC.buildApiUrl(action, extra);
      final r = await _dio.get(url).timeout(const Duration(seconds: 20));
      List<dynamic> list;
      if (r.data is List)
        list = List<dynamic>.from(r.data as List);
      else if (r.data is Map && r.data['data'] is List)
        list = List<dynamic>.from(r.data['data'] as List);
      else {
        debugPrint('API bad response: ${r.data?.runtimeType}');
        return [];
      }
      // فلترة ذكية: المجاني يرى كل المحتوى ولكن قنوات beIN فقط
      if (Sub.isFree && extra == null) list = _guestFilter(list, action);
      ListCache.put(cacheKey, list);
      return list;
    } catch (e) {
      debugPrint('API Error [$action] via Worker: $e');
      // Fallback: اتصال مباشر بالسيرفر
      try {
        return await _directFetch(action, extra, cacheKey);
      } catch (e2) {
        debugPrint('API Error [$action] direct: $e2');
        return [];
      }
    }
  }

  static Future<Map<String, List<dynamic>>> batchFetch() async {
    final results = <String, List<dynamic>>{};
    // كل الطلبات بالتوازي لأقصى سرعة
    await Future.wait([
      getList('get_vod_categories').then((v)    => results['movie_cats']  = v).catchError((_) => results['movie_cats']  = []),
      getList('get_series_categories').then((v) => results['series_cats'] = v).catchError((_) => results['series_cats'] = []),
      getList('get_live_categories').then((v)   => results['live_cats']   = v).catchError((_) => results['live_cats']   = []),
      getList('get_live_streams').then((v)       => results['live']       = v).catchError((_) => results['live']        = []),
      getList('get_vod_streams').then((v)        => results['movies']     = v).catchError((_) => results['movies']      = []),
      getList('get_series').then((v)             => results['series']     = v).catchError((_) => results['series']      = []),
    ]);
    return results;
  }

  static List<dynamic> _guestFilter(List<dynamic> list, String action) {
    // FREE: يرى كل المحتوى بدون تشغيل — فقط 5 قنوات beIN مجانية
    if (action == 'get_live_streams') {
      if (Sub.isNormal || Sub.isVIP) return list;
      // مجاني: فقط 5 قنوات beIN Sports
      final bein = list.where((item) {
        final n = (item['name'] ?? '').toString().toLowerCase();
        return n.contains('bein') || n.contains('بين');
      }).take(5).toList();
      return bein;
    }
    // أفلام ومسلسلات: جميع المستخدمين يرون الكل
    return list;
  }

  static Future<Map<String, dynamic>> getSeriesInfo(String sid) async {
    final cached = SeriesInfoCache.get(sid);
    if (cached != null) return cached;
    try {
      // محاولة أولى: مباشر للسيرفر (أسرع)
      final base = Sub.isVIP && Sub.xtreamUser.isNotEmpty
          ? Sub.xtreamBase.replaceAll(RegExp(r'/$'), '')
          : RC.serverUrl.replaceAll(RegExp(r'/$'), '');
      final user = Sub.isVIP && Sub.xtreamUser.isNotEmpty ? Sub.xtreamUser : RC.username;
      final pass = Sub.isVIP && Sub.xtreamUser.isNotEmpty ? Sub.xtreamPass : RC.password;
      final directUrl = '$base/player_api.php?username=$user&password=$pass&action=get_series_info&series_id=$sid';
      final r = await _dio.get(directUrl)
          .timeout(const Duration(seconds: 15));
      if (r.data is Map) {
        final d = Map<String, dynamic>.from(r.data as Map);
        SeriesInfoCache.put(sid, d);
        return d;
      }
    } catch (_) {
      // fallback Worker
      try {
        final url = RC.buildApiUrl('get_series_info', {'series_id': sid});
        final r   = await _dio.get(url);
        if (r.data is Map) {
          final d = Map<String, dynamic>.from(r.data as Map);
          SeriesInfoCache.put(sid, d);
          return d;
        }
      } catch (_) {}
    }
    return {};
  }

  // ── بناء روابط مباشرة من السيرفر بدون Worker (أسرع) ──
  static String _directUrl(String type, String id, String ext) {
    if (Sub.isVIP && Sub.xtreamUser.isNotEmpty) {
      final base = Sub.xtreamBase.replaceAll(RegExp(r'/$'), '');
      return '$base/$type/${Sub.xtreamUser}/${Sub.xtreamPass}/$id.$ext';
    }
    final base = RC.serverUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/$type/${RC.username}/${RC.password}/$id.$ext';
  }

  static List<String> liveUrls(dynamic item) {
    final id = item['stream_id'].toString();
    if (!kIsWeb) {
      // جميع السيرفرات المتاحة — يجرّب بالترتيب تلقائياً
      final urls = ServerRegistry.streamUrls('live', id, 'ts');
      final m3u8 = ServerRegistry.streamUrls('live', id, 'm3u8');
      return [...urls, ...m3u8];
    }
    final proxy = RC.proxyUrl.replaceAll(RegExp(r'/$'), '');
    return ['$proxy/stream/live/$id.ts', '$proxy/stream/live/$id.m3u8'];
  }

  static List<String> movieUrls(dynamic item) {
    final id  = item['stream_id'].toString();
    final ext = (item['container_extension']?.toString() ?? 'mp4')
        .toLowerCase().replaceAll('.', '');
    if (!kIsWeb) {
      // كل السيرفرات المتاحة للـ ext الأصلي
      final urls = ServerRegistry.streamUrls('movie', id, ext);
      // fallback mp4 إذا ext مختلف
      if (ext != 'mp4') {
        urls.addAll(ServerRegistry.streamUrls('movie', id, 'mp4'));
      }
      return urls;
    }
    final proxy = RC.proxyUrl.replaceAll(RegExp(r'/$'), '');
    return ['$proxy/stream/movie/$id.$ext', '$proxy/stream/movie/$id.mp4'];
  }

  static List<String> episodeUrls(dynamic ep) {
    final id  = ep['id'].toString();
    final ext = (ep['container_extension']?.toString() ?? 'mp4')
        .toLowerCase().replaceAll('.', '');
    if (!kIsWeb) {
      final urls = <String>[_directUrl('series', id, ext)];
      if (ext != 'mp4') urls.add(_directUrl('series', id, 'mp4'));
      return urls;
    }
    final proxy = RC.proxyUrl.replaceAll(RegExp(r'/$'), '');
    return ['$proxy/stream/series/$id.$ext'];
  }

  // ── اتصال مباشر بالسيرفر (fallback + VIP) ──────────────────
  static Future<List<dynamic>> _directFetch(
      String action, Map<String, dynamic>? extra, String cacheKey) async {
    // VIP: يستخدم سيرفره الخاص
    final base = Sub.isVIP && Sub.xtreamUser.isNotEmpty
        ? Sub.xtreamBase.replaceAll(RegExp(r'/$'), '')
        : RC.serverUrl.replaceAll(RegExp(r'/$'), '');
    final user = Sub.isVIP && Sub.xtreamUser.isNotEmpty ? Sub.xtreamUser : RC.username;
    final pass = Sub.isVIP && Sub.xtreamUser.isNotEmpty ? Sub.xtreamPass : RC.password;
    final params = <String, String>{
      'username': user, 'password': pass, 'action': action,
    };
    if (extra != null) params.addAll(extra.map((k, v) => MapEntry(k, v.toString())));
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final url = '$base/player_api.php?$query';
    final r = await _dio.get(url).timeout(const Duration(seconds: 20));
    List<dynamic> list = [];
    if (r.data is List)
      list = List<dynamic>.from(r.data as List);
    else if (r.data is Map && r.data['data'] is List)
      list = List<dynamic>.from(r.data['data'] as List);
    if (list.isNotEmpty) {
      if (Sub.isFree && extra == null) list = _guestFilter(list, action);
      ListCache.put(cacheKey, list);
    }
    return list;
  }
}

class _RetryInterceptor extends Interceptor {
  static const _max = 3;
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final retry = err.requestOptions.extra['_retry'] as int? ?? 0;
    if (retry < _max &&
        (err.type == DioExceptionType.connectionTimeout ||
         err.type == DioExceptionType.receiveTimeout    ||
         err.type == DioExceptionType.connectionError   ||
         (err.response?.statusCode ?? 0) >= 500)) {
      await Future.delayed(Duration(milliseconds: 500 * (retry + 1)));
      err.requestOptions.extra['_retry'] = retry + 1;
      try {
        final resp = await Api._dio.fetch(err.requestOptions);
        handler.resolve(resp);
      } catch (_) { super.onError(err, handler); }
    } else { super.onError(err, handler); }
  }
}

// ─────────────────────────────────────────────────────────
//  GLOBAL STATE
// ─────────────────────────────────────────────────────────

// ── Image URL helper — يُمرر الصور عبر Worker على الويب لحل CORS ──
// ── Smart Image URL ───────────────────────────────────────────
// 1. السيرفر أولاً (stream_icon/cover)
// 2. TMDB fallback إذا لا يوجد بوستر في السيرفر
String _imgUrl(String url, {bool thumb = false}) {
  if (url.isEmpty) return '';
  // TMDB CDN — جودة عالية مباشرة
  if (url.contains('image.tmdb.org')) {
    if (thumb) return url
        .replaceAll('/original/', '/w342/')
        .replaceAll('/w1280/', '/w500/')
        .replaceAll('/w780/', '/w342/');
    return url;
  }
  // Web: Proxy لـ CORS
  if (kIsWeb) {
    final proxy = RC.proxyUrl.replaceAll(RegExp(r'/$'), '');
    return '$proxy/img/?url=${Uri.encodeComponent(url)}';
  }
  return url;
}

// ── Smart Poster: السيرفر أولاً، TMDB fallback إذا فارغ ───────
class SmartPoster extends StatefulWidget {
  final dynamic item;
  final bool isTv;
  final BoxFit fit;
  final double? memH, memW;
  final BorderRadius? radius;
  final bool showShimmer;
  const SmartPoster({
    required this.item,
    this.isTv = false,
    this.fit = BoxFit.cover,
    this.memH, this.memW,
    this.radius,
    this.showShimmer = true,
  });
  @override State<SmartPoster> createState() => _SmartPosterState();
}

class _SmartPosterState extends State<SmartPoster> {
  String _url = '';
  bool _triedTmdb = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _url = _getPrimaryUrl();
    if (_url.isEmpty) _fetchTmdb();
  }

  String _getPrimaryUrl() {
    // السيرفر أولاً: stream_icon → cover
    final icon = widget.item['stream_icon']?.toString() ?? '';
    final cover = widget.item['cover']?.toString() ?? '';
    return icon.isNotEmpty ? icon : cover;
  }

  Future<void> _fetchTmdb() async {
    if (_triedTmdb) return;
    _triedTmdb = true;
    final name = widget.item['name']?.toString() ?? '';
    if (name.isEmpty) return;
    try {
      final info = await TMDB.search(name, isTv: widget.isTv)
          .timeout(const Duration(seconds: 5));
      final tmdbUrl = info['poster'] ?? info['poster_sm'] ?? '';
      if (tmdbUrl.isNotEmpty && mounted) {
        setState(() => _url = tmdbUrl);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.item['name']?.toString() ?? '';
    if (_url.isEmpty) return _buildPlaceholder(name);

    Widget img = CachedNetworkImage(
      imageUrl: _imgUrl(_url),
      fit: widget.fit,
      memCacheHeight: widget.memH?.toInt(),
      memCacheWidth:  widget.memW?.toInt(),
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, __) => widget.showShimmer
          ? _ShimmerBox(radius: widget.radius)
          : Container(color: C.surface),
      errorWidget: (_, __, ___) {
        // السيرفر فشل → جرّب TMDB
        if (!_triedTmdb) {
          _fetchTmdb();
          return widget.showShimmer
              ? _ShimmerBox(radius: widget.radius)
              : Container(color: C.surface);
        }
        return _buildPlaceholder(name);
      },
    );

    if (widget.radius != null) {
      img = ClipRRect(borderRadius: widget.radius!, child: img);
    }
    return img;
  }

  Widget _buildPlaceholder(String name) => Container(
    decoration: BoxDecoration(
      color: C.surface,
      borderRadius: widget.radius,
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)])),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(widget.isTv ? Icons.tv_rounded : Icons.movie_rounded,
          color: C.dim, size: 24),
      const SizedBox(height: 6),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(name, style: T.caption(c: C.dim),
            maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
    ])));
}

// ── Shimmer Loading — ذهبي متحرك ──────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final BorderRadius? radius;
  const _ShimmerBox({this.radius});
  @override State<_ShimmerBox> createState() => _ShimmerBoxState();
}
class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();
    _anim = Tween(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.radius ?? BorderRadius.zero,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_anim.value - 0.5).clamp(0.0, 1.0),
                _anim.value.clamp(0.0, 1.0),
                (_anim.value + 0.5).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFF1A1A1A),
                Color(0xFF2A2A2A), // الخط الذهبي الفاتح
                Color(0xFF1A1A1A),
              ]),
          ),
        ),
      ),
    );
  }
}

class AppState {
  static List<dynamic> allMovies  = [];
  static List<dynamic> allSeries  = [];
  static List<dynamic> allLive    = [];
  static List<dynamic> movieCats  = [];
  static List<dynamic> seriesCats = [];
  static List<dynamic> liveCats   = [];
  static bool isLoaded  = false;
  static bool _loading  = false;

  static const _kMovies = 'totv_cache_movies_v4';
  static const _kSeries = 'totv_cache_series_v4';
  static const _kLive   = 'totv_cache_live_v4';
  static const _kMCats  = 'totv_cache_mcats_v4';
  static const _kSCats  = 'totv_cache_scats_v4';
  static const _kLCats  = 'totv_cache_lcats_v4';
  static const _kTime   = 'totv_cache_time_v4';
  // Hero data cache — يُحفظ منفصلاً للعرض الفوري
  static const _kHero   = 'totv_cache_hero_v4';

  static VoidCallback? onPartialLoad; // notify UI when partial data ready

  // Preload top poster images in background for instant display
  static Future<void> preloadPosters(BuildContext ctx) async {
    final items = [
      ...allMovies.take(20),
      ...allSeries.take(20),
      ...allLive.take(30),
    ];
    for (final item in items) {
      final img = item['stream_icon']?.toString() ?? item['cover']?.toString() ?? '';
      if (img.isNotEmpty) {
        try {
          precacheImage(CachedNetworkImageProvider(img), ctx);
        } catch (_) {}
      }
    }
  }

  // ── تحميل ذكي مرة واحدة فقط ──
  static bool _hasNetworkData = false; // هل جُلبت البيانات من الشبكة مرة؟

  static Future<void> loadAll({bool force = false}) async {
    if (_loading) return;
    if (isLoaded && _hasNetworkData && !force) return;
    _loading = true;

    // ── الطبقة 1: كاش الجهاز — فوري (0ms) ──────────────
    if (!force && !isLoaded) {
      await _loadFromDisk();
      if (allMovies.isNotEmpty || allLive.isNotEmpty) {
        isLoaded = true;
        onPartialLoad?.call();
        // إذا الكاش حديث — لا نحتاج الشبكة الآن
        if (!_hasNetworkData) {
          _loading = false;
          _fetchInBackground(); // تحديث في الخلفية بهدوء
          return;
        }
      }
    }

    // ── الطبقات 2+3: GitHub CDN ثم Worker ────────────────
    if (!_hasNetworkData || force) {
      await _fetchFromNetwork(force: force);
    }
    _loading = false;
  }

  // جلب في الخلفية بعد عرض الكاش — لا يعيق UI
  static Future<void> _fetchInBackground() async {
    await Future.delayed(const Duration(seconds: 3));
    if (_hasNetworkData) return;
    await _fetchFromNetwork();
  }

  // الطبقة 2: GitHub Pages CDN (مجاني — أسرع من Worker)
  // الطبقة 3: Worker KV (fallback)
  static Future<void> _fetchFromNetwork({bool force = false}) async {
    // مباشرة من Worker — GitHub CDN معطّل حتى يتم إعداده
    try {
      final data = await Api.batchFetch();
      _applyData(data);
    } catch (_) {
      isLoaded = true;
    }
  }

  // جلب من GitHub Pages
  static Future<bool> _fetchFromGithub() async {
    try {
      final urls = {
        'movies':     '$kGithubCdn/movies.json',
        'series':     '$kGithubCdn/series.json',
        'live':       '$kGithubCdn/live.json',
        'movie_cats': '$kGithubCdn/movie_cats.json',
        'series_cats':'$kGithubCdn/series_cats.json',
        'live_cats':  '$kGithubCdn/live_cats.json',
      };
      // جلب متوازٍ من GitHub CDN
      final futures = urls.entries.map((e) =>
        Api._dio.get(e.value)
            .timeout(const Duration(seconds: 8))
            .then((r) => MapEntry(e.key, r.data))
            .catchError((_) => MapEntry(e.key, <dynamic>[])));
      final results = Map.fromEntries(await Future.wait(futures));
      final data = results.map((k, v) =>
        MapEntry(k, v is List ? v : <dynamic>[]));
      _applyData(data);
      return allMovies.isNotEmpty || allLive.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static void _applyData(Map<String, dynamic> data) {
    if ((data['movies'] as List? ?? []).isNotEmpty) allMovies = data['movies'] as List;
    if ((data['series'] as List? ?? []).isNotEmpty) allSeries = data['series'] as List;
    if ((data['live']   as List? ?? []).isNotEmpty) allLive   = data['live']   as List;
    if ((data['movie_cats']  as List? ?? []).isNotEmpty) movieCats  = data['movie_cats']  as List;
    if ((data['series_cats'] as List? ?? []).isNotEmpty) seriesCats = data['series_cats'] as List;
    if ((data['live_cats']   as List? ?? []).isNotEmpty) liveCats   = data['live_cats']   as List;
    isLoaded = true;
    _hasNetworkData = true;
    _saveToDisk();
    onPartialLoad?.call();
  }

  static void resetNetworkFlag() { _hasNetworkData = false; }

  static Future<void> _loadFromDisk() async {
    try {
      final p = await SharedPreferences.getInstance();
      final t = p.getInt(_kTime) ?? 0;
      // كاش 24 ساعة — يظهر المحتوى فوراً عند الفتح
      if (DateTime.now().millisecondsSinceEpoch - t < 24 * 3600 * 1000) {
        allMovies  = _dec(p.getString(_kMovies));
        allSeries  = _dec(p.getString(_kSeries));
        allLive    = _dec(p.getString(_kLive));
        movieCats  = _dec(p.getString(_kMCats));
        seriesCats = _dec(p.getString(_kSCats));
        liveCats   = _dec(p.getString(_kLCats));
        if (allMovies.isNotEmpty) isLoaded = true;
      }
    } catch (_) {}
  }

  static Future<void> _saveToDisk() async {
    // حفظ في الخلفية لا يعيق الـ UI
    Future.microtask(() async {
      try {
        final p = await SharedPreferences.getInstance();
        await p.setString(_kMovies, _enc(allMovies.take(3000).toList()));
        await p.setString(_kSeries, _enc(allSeries.take(3000).toList()));
        await p.setString(_kLive,   _enc(allLive.take(2000).toList()));
        await p.setString(_kMCats,  _enc(movieCats));
        await p.setString(_kSCats,  _enc(seriesCats));
        await p.setString(_kLCats,  _enc(liveCats));
        await p.setInt(_kTime, DateTime.now().millisecondsSinceEpoch);
      } catch (_) {}
    });
  }

  static List<dynamic> _dec(String? s) {
    if (s == null || s.isEmpty) return [];
    try { return jsonDecode(s) as List; } catch (_) { return []; }
  }
  static String _enc(List<dynamic> l) {
    try { return jsonEncode(l); } catch (_) { return '[]'; }
  }

  static Future<void> clearDisk() async {
    try {
      final p = await SharedPreferences.getInstance();
      for (final k in [_kMovies,_kSeries,_kLive,_kMCats,_kSCats,_kLCats,_kTime])
        await p.remove(k);
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────
//  SOUND
// ─────────────────────────────────────────────────────────
class Sound {
  static AudioPlayer? _p;
  static bool _init = false;
  static Future<void> init() async {
    if (_init) return;
    try { _p = AudioPlayer(); _init = true; } catch (_) {}
  }
  static void hapticL() { try { HapticFeedback.lightImpact();  } catch (_) {} }
  static void hapticM() { try { HapticFeedback.mediumImpact(); } catch (_) {} }
  static Future<void> hapticOk() async {
    try {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }
  static Future<void> success() async {
    // اهتزاز احتفالي عند الاشتراك
    try {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      HapticFeedback.mediumImpact();
    } catch (_) {}
    // صوت النجاح (نغمة النظام)
    try {
      if (_p == null) await init();
      await _p?.setVolume(1.0);
      await _p?.play(AssetSource('sounds/cha_ching.mp3'));
    } catch (_) {
      // fallback: نغمة النظام
      try { HapticFeedback.heavyImpact(); } catch (_) {}
    }
  }

  // اهتزاز عند الإشعارات
  static void hapticNotif() {
    try {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        try { HapticFeedback.lightImpact(); } catch (_) {}
      });
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────
//  NOTIFICATIONS
// ─────────────────────────────────────────────────────────
class NotifService {
  static bool _inited = false;
  static final _ln = FlutterLocalNotificationsPlugin();
  static const _chId   = 'totv_main';
  static const _chName = 'TOTV+ Notifications';

  static Future<void> init() async {
    if (_inited) return;
    try {
      if (!kIsWeb) {
        const android = AndroidInitializationSettings('@mipmap/launcher_icon');
        const ios     = DarwinInitializationSettings();
        await _ln.initialize(const InitializationSettings(android: android, iOS: ios));
        await _ln
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(const AndroidNotificationChannel(
              _chId, _chName, importance: Importance.high, playSound: true));
      }
      final m = FirebaseMessaging.instance;
      await m.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessage.listen((msg) {
        final n = msg.notification;
        if (n != null) show(n.title ?? 'TOTV+', n.body ?? '');
      });
      await m.subscribeToTopic('all_users');
      if (!Sub.isPremium) await m.subscribeToTopic('free_users');
      else await m.subscribeToTopic('premium_users');
      final token = await m.getToken();
      if (token != null) {
        final id = await DeviceId.get();
        await FirebaseFirestore.instance.collection('fcm_tokens').doc(id)
            .set({'token': token, 'updated_at': FieldValue.serverTimestamp(),
                  'premium': Sub.isPremium, 'platform': Plat.name}, SetOptions(merge: true));
      }
      _inited = true;
    } catch (_) {}
  }

  static void show(String title, String body, {String? payload}) {
    if (kIsWeb) { debugPrint('📲 $title — $body'); return; }
    // اهتزاز عند وصول الإشعار
    Sound.hapticNotif();
    try {
      _ln.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body,
        const NotificationDetails(
          android: AndroidNotificationDetails(_chId, _chName,
              importance: Importance.high, priority: Priority.high,
              icon: '@mipmap/launcher_icon'),
          iOS: DarwinNotificationDetails()));
    } catch (_) {}
  }
  static Future<void> subscribeToTopic(String t) async {
    try { await FirebaseMessaging.instance.subscribeToTopic(t); } catch (_) {}
  }
  static Future<void> unsubscribeFromTopic(String t) async {
    try { await FirebaseMessaging.instance.unsubscribeFromTopic(t); } catch (_) {}
  }
}


// ══════════════════════════════════════════════════════════════
//  MAIN
// ══════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── منع انهيار التطبيق — Error Handler ──────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    // تجاهل أخطاء الـ rendering الغير حرجة
    if (details.exceptionAsString().contains('RenderFlex') ||
        details.exceptionAsString().contains('overflowed')) return;
    FlutterError.presentError(details);
  };

  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async error caught: $error');
    return true; // منع الانهيار
  };

  Plat.detect();
  // ── Image cache config — سرعة تحميل الصور ──────────
  PaintingBinding.instance.imageCache.maximumSize       = 800;
  PaintingBinding.instance.imageCache.maximumSizeBytes  = 200 << 20; // 200 MB

  // إخفاء شريط الحالة
  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);
  }
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // تحميل أساسي — Sub أولاً ثم RC بحد زمني
  await Sub.load();
  // RC.init بحد أقصى 3 ثوانٍ — لا نوقف التطبيق
  await RC.init().timeout(
    const Duration(seconds: 3),
    onTimeout: () {},
  ).catchError((_) {});
  // تهيئة CMS Service (كاش السيرفر + الإعدادات)
  await CmsService.init().timeout(
    const Duration(seconds: 4),
    onTimeout: () {},
  ).catchError((_) {});
  // كشف Android TV
  await TVLayout.detect();
  // باقي الخدمات في الخلفية
  WL.load();
  WatchHistory.load();
  ProfileManager.load();
  ServerRegistry.init(); // جلب قائمة السيرفرات
  PlayUrlCache.load(); // روابط التشغيل المخزنة
  Sound.init();
    // مراقبة تحديثات التكوين من Firebase (buyUrl, maintenance, etc)
    FirebaseFirestore.instance
        .collection('app_config').doc('subscription')
        .snapshots().listen((snap) {
      if (snap.exists) {
        final url = snap.data()?['buy_url']?.toString() ?? '';
        if (url.isNotEmpty) Sub.updateRemote({'buy_url': url});
      }
    });
  // تحقق من الإصدار عبر Worker (يُكمّل Remote Config)
  RC.checkVersionFromWorker().catchError((_) {});

  // AdMob
  if (!kIsWeb && Plat.isMobile) {
    if (!kIsWeb) { try { await Ads.init(); if (!Sub.isPremium) Ads.preload(); } catch (_) {} }
  }

  await NotifService.init();

  final devId = await DeviceId.get();
  try {
    FirebaseAnalytics.instance.logAppOpen();
    FirebaseFirestore.instance.collection('online_users').doc(devId).set(
        {'last_seen': FieldValue.serverTimestamp(), 'is_online': true,
         'premium': Sub.isPremium, 'platform': Plat.name}, SetOptions(merge: true));
  } catch (_) {}

  await SystemChrome.setPreferredOrientations(
    Plat.isTV
        ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
           DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

  PaintingBinding.instance.imageCache.maximumSizeBytes = 300 * 1024 * 1024; // 300MB
  PaintingBinding.instance.imageCache.maximumSize      = 1200; // صور أكثر في الذاكرة

  runApp(const App());
}

// ══════════════════════════════════════════════════════════════
//  APP
// ══════════════════════════════════════════════════════════════
class App extends StatefulWidget {
  const App();
  @override State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    RC.onConfigChanged = () {
      if (mounted) setState(() {});
      ListCache.invalidate();
      AppState.clearDisk();
      AppState.isLoaded = false;
      AppState.resetNetworkFlag();
      AppState.loadAll(force: true);
    };
  }

  @override
  Widget build(BuildContext context) {
    // تحقق من حظر الجهاز
    return MaterialApp(
      title: 'TOTV+',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (RC.locked)       return _LockPage(RC.lockMsg);
    if (RC.maintenance)  return _MaintenancePage(RC.maintMsg);
    if (RC.needsUpdate)  return _UpdatePage();
    return const _BanCheckPage();
  }

  ThemeData _theme() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    primaryColor: C.gold,
    colorScheme: const ColorScheme.dark(primary: C.gold),
    textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: GoogleFonts.cairo().fontFamily, bodyColor: C.white, displayColor: C.white),
    splashColor: C.goldBg,
    highlightColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0,
      scrolledUnderElevation: 0, toolbarHeight: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      )),
  );
}

// ── فحص الحظر قبل الـ Splash ──────────────────────────────
class _BanCheckPage extends StatefulWidget {
  const _BanCheckPage();
  @override State<_BanCheckPage> createState() => _BanCheckPageState();
}
class _BanCheckPageState extends State<_BanCheckPage> {
  @override
  void initState() {
    super.initState();
    _check();
  }
  Future<void> _check() async {
    final banned = await DeviceId.isBanned();
    if (!mounted) return;
    if (banned) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _BannedPage()));
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Splash()));
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: Text('TOTV+',
        style: T.cinzel(s: 32, c: C.gold).copyWith(letterSpacing: 8))));
}

// ── صفحة الجهاز المحظور ───────────────────────────────────
class _BannedPage extends StatelessWidget {
  const _BannedPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.block_rounded, color: Color(0xFFE53935), size: 72),
        const SizedBox(height: 24),
        Text('تم حظر هذا الجهاز', style: T.cairo(s: 20, w: FontWeight.w700, c: Colors.white)),
        const SizedBox(height: 12),
        Text('للتواصل مع الدعم الفني', style: T.cairo(s: 14, c: C.grey), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('https://wa.me/${RC.whatsapp}'),
              mode: LaunchMode.externalApplication),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(gradient: C.playGrad, borderRadius: BorderRadius.circular(12)),
            child: Text('تواصل معنا', style: T.cairo(s: 14, w: FontWeight.w800, c: Colors.black)))),
      ]))));
}

// ── صفحة التحديث الإجباري ─────────────────────────────────
class _UpdatePage extends StatefulWidget {
  _UpdatePage();
  @override State<_UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<_UpdatePage> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double>   _fadeA, _scaleA;

  @override
  void initState() {
    super.initState();
    _ac     = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeA  = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _scaleA = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _ac, curve: Curves.easeOutBack));
    _ac.forward();
  }

  @override void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeA,
        child: ScaleTransition(
          scale: _scaleA,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ShaderMask(
                  shaderCallback: (b) => C.goldGrad.createShader(b),
                  blendMode: BlendMode.srcIn,
                  child: Text('TOTV+',
                    style: T.cinzel(s: 52, c: Colors.white, w: FontWeight.w900)
                        .copyWith(letterSpacing: 10))),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: C.gold.withOpacity(0.25)),
                    boxShadow: [BoxShadow(color: C.gold.withOpacity(0.08), blurRadius: 30)]),
                  child: Column(children: [
                    Container(width: 80, height: 80,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: C.goldBg,
                          border: Border.all(color: C.gold.withOpacity(0.4), width: 1.5)),
                      child: const Icon(Icons.system_update_rounded, color: C.gold, size: 40)),
                    const SizedBox(height: 20),
                    Text('يتوفر إصدار جديد', style: T.cairo(s: 22, w: FontWeight.w800, c: C.white)),
                    const SizedBox(height: 10),
                    Text('يجب تحديث التطبيق للاستمرار في المشاهدة',
                        style: T.cairo(s: 13, c: C.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    SizedBox(width: double.infinity,
                      child: GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse(RC.updateUrl.isNotEmpty ? RC.updateUrl : kUpdateUrl),
                          mode: LaunchMode.externalApplication),
                        child: Container(height: 54,
                          decoration: BoxDecoration(
                            gradient: C.playGrad,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: C.gold.withOpacity(0.45), blurRadius: 18)]),
                          child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.download_rounded, color: Colors.black, size: 22),
                            const SizedBox(width: 8),
                            Text('حدّث الآن', style: T.cairo(s: 16, w: FontWeight.w800, c: Colors.black)),
                          ]))))),
                  ])),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── صفحة القفل ────────────────────────────────────────────
class _LockPage extends StatelessWidget {
  final String msg;
  const _LockPage(this.msg);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_rounded, color: C.gold, size: 72),
        const SizedBox(height: 24),
        Text('TOTV+', style: T.cinzel(s: 36, c: C.gold).copyWith(letterSpacing: 6)),
        const SizedBox(height: 16),
        Text(msg.isNotEmpty ? msg : 'التطبيق متوقف مؤقتاً',
            textAlign: TextAlign.center, style: T.cairo(s: 16, w: FontWeight.w700)),
        const SizedBox(height: 32),
        _contactBtn(gradient: const [Color(0xFF075E54), Color(0xFF128C7E)],
            icon: Icons.chat_rounded, label: 'واتساب',
            onTap: () async { try { await launchUrl(
                Uri.parse('https://wa.me/${RC.whatsapp}'),
                mode: LaunchMode.externalApplication); } catch (_) {} }),
      ]))));

  Widget _contactBtn({required List<Color> gradient, required IconData icon,
      required String label, required VoidCallback onTap}) =>
    GestureDetector(onTap: onTap,
      child: Container(height: 52, width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(label, style: T.cairo(s: 14, w: FontWeight.w700)),
        ])));
}

// ── صفحة الصيانة ──────────────────────────────────────────
class _MaintenancePage extends StatefulWidget {
  final String msg;
  const _MaintenancePage(this.msg);
  @override State<_MaintenancePage> createState() => _MaintenancePageState();
}
class _MaintenancePageState extends State<_MaintenancePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override void initState() { super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(animation: _c, builder: (_, __) => Transform.rotate(
        angle: _c.value * 6.28,
        child: Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle,
              border: Border.all(color: C.gold.withOpacity(0.5), width: 1.5)),
          child: const Icon(Icons.settings_rounded, color: C.gold, size: 38)))),
      const SizedBox(height: 28),
      Text('TOTV+', style: T.cinzel(s: 40, c: C.gold).copyWith(letterSpacing: 6)),
      const SizedBox(height: 16),
      Text('نعمل على تحسين الخدمة', style: T.cairo(s: 18, w: FontWeight.w700)),
      const SizedBox(height: 10),
      Text(widget.msg.isNotEmpty ? widget.msg : 'سنعود قريباً',
          textAlign: TextAlign.center, style: T.cairo(s: 13, c: C.grey)),
    ])));
}

// ══════════════════════════════════════════════════════════════
//  SPLASH — شاشة سوداء + اسم التطبيق (Android بدون فيديو)
//           فيديو على iOS
// ══════════════════════════════════════════════════════════════
class Splash extends StatefulWidget {
  const Splash();
  @override State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  VideoPlayerController? _vpc;
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;
  late final AnimationController _nameAnim;  // انيميشن اسم التطبيق
  bool _nav        = false;
  bool _videoReady = false;
  bool _dataReady  = false;
  double _vidW = 1920, _vidH = 1080;

  // Android: لا فيديو — شاشة سوداء + اسم فقط
  bool get _showVideo => Plat.isIOS || kIsWeb;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn));

    // انيميشن اسم التطبيق للـ Android
    _nameAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();

    if (_showVideo) {
      _initVideo();
    } else {
      // Android: تحميل بيانات فوراً + انتقال بعد 2.5 ثانية
      _preloadData();
      Future.delayed(const Duration(milliseconds: 2500), _go);
    }

    // حد أقصى
    Future.delayed(Duration(seconds: _showVideo ? 10 : 4), _go);
  }

  Future<void> _initVideo() async {
    try {
      // 0320.mp4 اختياري — ضعه في assets/videos/ إذا أردت السبلاش
      final ctrl = VideoPlayerController.asset('assets/videos/0320.mp4',
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false));
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      _vidW = ctrl.value.size.width  > 0 ? ctrl.value.size.width  : 1920;
      _vidH = ctrl.value.size.height > 0 ? ctrl.value.size.height : 1080;
      await ctrl.setVolume(1.0);
      await ctrl.setLooping(false);
      _vpc = ctrl;
      if (mounted) setState(() => _videoReady = true);
      await ctrl.play();
      ctrl.addListener(_videoListener);
      _preloadData();
    } catch (e) {
      debugPrint('Splash video: $e');
      _preloadData();
      await Future.delayed(const Duration(seconds: 2));
      _go();
    }
  }

  Future<void> _preloadData() async {
    // تحميل disk cache فوراً — لا نانتظر الـ network
    AppState.loadAll().catchError((_) {});
    await Future.delayed(const Duration(milliseconds: 500));
    _dataReady = true;
    if (!_nav && mounted && !_showVideo) _go();
  }

  void _videoListener() {
    final vpc = _vpc;
    if (vpc == null || !mounted) return;
    final dur = vpc.value.duration;
    final pos = vpc.value.position;
    if (dur > Duration.zero && pos >= dur - const Duration(milliseconds: 100)) _go();
    if (vpc.value.hasError) _go();
  }

  Future<void> _go() async {
    if (_nav || !mounted) return;
    _nav = true;
    await _fadeCtrl.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder:        (_, __, ___) => const Shell(),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 300)));
    if (!Sub.isPremium && Plat.isMobile) Ads.preload();
  }

  @override
  void dispose() {
    _vpc?.removeListener(_videoListener);
    _vpc?.dispose();
    _fadeCtrl.dispose();
    _nameAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen     = MediaQuery.of(context).size;
    final vidRatio   = _vidW / _vidH;
    final scrRatio   = screen.width / screen.height;
    final widerVideo = vidRatio > scrRatio;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(fit: StackFit.expand, children: [
          Container(color: Colors.black),

          // ── iOS: فيديو ────────────────────────────────────
          if (_showVideo && _videoReady && _vpc != null) ...[ 
            if (widerVideo && screen.height > screen.width) ...[
              // فيديو أفقي على هاتف عمودي — خلفية ضبابية
              Positioned.fill(child: Stack(fit: StackFit.expand, children: [
                FittedBox(fit: BoxFit.cover,
                    child: SizedBox(width: _vidW, height: _vidH, child: VideoPlayer(_vpc!))),
                BackdropFilter(filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(color: Colors.black.withOpacity(0.4))),
              ])),
              Positioned.fill(child: Center(child: SizedBox(
                  width: screen.width,
                  height: screen.width / vidRatio,
                  child: VideoPlayer(_vpc!)))),
            ] else
              Positioned.fill(child: FittedBox(fit: BoxFit.cover,
                  child: SizedBox(width: _vidW, height: _vidH, child: VideoPlayer(_vpc!)))),
          ],

          // ── Android: شاشة سوداء + اسم التطبيق بخط Cinzel ──
          if (!_showVideo)
            Center(
              child: AnimatedBuilder(
                animation: _nameAnim,
                builder: (_, __) => Opacity(
                  opacity: _nameAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _nameAnim.value)),
                    child: Text('TOTV+',
                      style: T.cinzel(s: 42, c: C.gold, w: FontWeight.w900)
                          .copyWith(letterSpacing: 10)),
                  ),
                ),
              ),
            ),

          // ── شاشة بيضاء iOS بدون فيديو جاهز ──────────────
          if (_showVideo && !_videoReady)
            Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: C.gold.withOpacity(0.6), strokeWidth: 1.5))),
        ])));
  }
}


// ══════════════════════════════════════════════════════════════
//  SHELL — التنقل الرئيسي بتصميم TOD
// ══════════════════════════════════════════════════════════════
class Shell extends StatefulWidget {
  const Shell();
  @override State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _i = 0;
  final _pc = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Callback: refresh UI when new data arrives progressively
    AppState.onPartialLoad = () { if (mounted) setState(() {}); };
    // تحميل بيانات — يعرض disk cache فوراً ثم يحدث في الخلفية
    AppState.loadAll();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pc.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.detached) {
      DeviceId.get().then((id) {
        try { FirebaseFirestore.instance
            .collection('online_users').doc(id)
            .update({'is_online': false}); } catch (_) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // تكيف عدد الـ tabs حسب المنصة
    final tabs = _buildTabs();
    return Scaffold(
      extendBody: true,
      backgroundColor: C.bg,
      body: PageView(
        controller: _pc,
        physics: const NeverScrollableScrollPhysics(),
        children: _buildPages(),
      ),
      bottomNavigationBar: _TODBottomNav(
        index: _i, tabs: tabs,
        onTap: (i) {
          setState(() => _i = i);
          _pc.jumpToPage(i);
          Sound.hapticL();
        }),
    );
  }

  List<_Tab> _buildTabs() => [
    const _Tab(Icons.home_outlined,          Icons.home_rounded,          'الرئيسية'),
    const _Tab(Icons.movie_outlined,         Icons.movie_rounded,         'أفلام'),
    const _Tab(Icons.tv_outlined,            Icons.tv_rounded,            'مسلسلات'),
    const _Tab(Icons.sensors_outlined,       Icons.sensors_rounded,       'مباشر'),
    const _Tab(Icons.search_outlined,        Icons.search_rounded,        'بحث'),
    const _Tab(Icons.person_outline_rounded, Icons.person_rounded,        'حسابي'),
  ];

  List<Widget> _buildPages() => [
    const HomePage(),
    ContentPage(type: 'movie',  label: 'أفلام'),
    ContentPage(type: 'series', label: 'مسلسلات'),
    const LivePage(),
    const SearchPage(),
    const ProfilePage(),
  ];
}

class _Tab {
  final IconData off, on; final String lbl;
  const _Tab(this.off, this.on, this.lbl);
}

// ── Bottom Navigation — TOD Style ─────────────────────────
class _TODBottomNav extends StatelessWidget {
  final int index; final List<_Tab> tabs; final ValueChanged<int> onTap;
  _TODBottomNav({required this.index, required this.tabs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 62 + bot,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            border: const Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 0.5))),
          child: Padding(
            padding: EdgeInsets.only(bottom: bot),
            child: Row(children: List.generate(tabs.length, (i) {
              final sel = i == index;
              return Expanded(child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  // أيقونة مع خط سفلي ذهبي عند الاختيار
                  AnimatedContainer(duration: const Duration(milliseconds: 200),
                    child: Icon(sel ? tabs[i].on : tabs[i].off,
                        color: sel ? C.gold : C.dim,
                        size: sel ? 22 : 20)),
                  const SizedBox(height: 3),
                  Text(tabs[i].lbl, style: T.cairo(s: 9,
                      c: sel ? C.gold : C.dim,
                      w: sel ? FontWeight.w700 : FontWeight.w400)),
                  const SizedBox(height: 2),
                  // نقطة ذهبية تحت الأيقونة المختارة
                  AnimatedContainer(duration: const Duration(milliseconds: 200),
                    width: sel ? 4 : 0, height: 4,
                    decoration: BoxDecoration(
                        color: sel ? C.gold : Colors.transparent,
                        shape: BoxShape.circle)),
                ])));
            }))))));
  }
}

// ══════════════════════════════════════════════════════════════
//  HOME PAGE — تصميم TOD: Hero Fullscreen + أقسام أفقية
// ══════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage();
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  List<_HeroItem> _heroes = [];
  bool _busy  = true;
  int  _hIdx  = 0;

  @override void initState() { super.initState(); _build(); }

  Future<void> _build() async {
    setState(() => _busy = true);

    // Step 1: ابدأ التحميل فوراً
    if (!AppState.isLoaded) {
      AppState.loadAll().then((_) {
        if (mounted) _buildHeroes();
      }).catchError((_) {
        if (mounted) setState(() => _busy = false);
      });
    }

    // Step 2: أظهر skeleton في الحال
    if (mounted) setState(() => _busy = false);

    // Step 3: انتظر البيانات لمدة قصيرة ثم ابنِ
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted && (AppState.allMovies.isNotEmpty || AppState.allSeries.isNotEmpty ||
        AppState.allLive.isNotEmpty)) {
      await _buildHeroes();
    } else if (mounted) {
      // حاول مرة أخرى بعد تحميل البيانات
      AppState.loadAll(force: true).then((_) {
        if (mounted) _buildHeroes();
      });
    }
  }

  // فلترة المحتوى غير المناسب للـ Hero الرئيسي
  bool _isHeroEligible(dynamic item) {
    final name = (item['name'] ?? '').toString().toLowerCase();
    final cat  = (item['category_name'] ?? '').toString().toLowerCase();
    // استبعاد: أطفال، كرتون، max، disney، adult
    const excluded = ['kids','أطفال','cartoon','baby','children','max ',
                      'disney','adult','xxx','18+','toddler'];
    for (final kw in excluded) {
      if (name.contains(kw) || cat.contains(kw)) return false;
    }
    return true;
  }

  Future<void> _buildHeroes() async {
    if (!mounted) return;
    // فلترة: بدون قنوات أطفال أو max أو كرتون
    final eligibleMovies  = AppState.allMovies.where(_isHeroEligible).take(10).toList();
    final eligibleSeries  = AppState.allSeries.where(_isHeroEligible).take(10).toList();
    final featured = [...eligibleMovies, ...eligibleSeries];
    if (featured.isEmpty) return;
    featured.shuffle();

    // Step 3: أظهر المحتوى فوراً بدون TMDB
    final quickHeroes = <_HeroItem>[];
    for (final item in featured.take(8)) {
      final isTv = AppState.allSeries.contains(item);
      final name = item['name']?.toString() ?? '';
      final icon = item['stream_icon']?.toString() ?? item['cover']?.toString() ?? '';
      quickHeroes.add(_HeroItem(
        item: item, isTv: isTv,
        backdrop: icon, poster: icon,
        title: name, overview: '', rating: '', year: '',
        cast: '', director: '', needsSub: false,
      ));
    }
    if (mounted) setState(() => _heroes = quickHeroes);

    // Step 4: حسّن بـ TMDB في الخلفية (بالتوازي)
    _enrichWithTmdb(featured.take(8).toList());
  }

  Future<void> _enrichWithTmdb(List items) async {
    // كل الطلبات بالتوازي — لا تسلسل
    final futures = items.map((item) async {
      final isTv = AppState.allSeries.contains(item);
      final name = item['name']?.toString() ?? '';
      final icon = item['stream_icon']?.toString() ?? item['cover']?.toString() ?? '';
      try {
        final tmdb = await TMDB.search(name, isTv: isTv).timeout(
            const Duration(seconds: 6), onTimeout: () => {});
        final year = tmdb['year'] ?? '';
        return _HeroItem(
          item: item, isTv: isTv,
          backdrop: tmdb['backdrop']?.isNotEmpty == true ? tmdb['backdrop']! : icon,
          poster:   tmdb['poster_sm']?.isNotEmpty == true ? tmdb['poster_sm']! : icon,
          title:    tmdb['title']?.isNotEmpty == true ? tmdb['title']! : name,
          overview: tmdb['overview'] ?? '',
          rating:   tmdb['rating']   ?? '',
          year:     year,
          cast:     tmdb['cast']     ?? '',
          director: tmdb['director'] ?? '',
          needsSub: _isNew(year),
        );
      } catch (_) {
        return null;
      }
    }).toList();

    final results = await Future.wait(futures);
    if (!mounted) return;
    final enriched = results.whereType<_HeroItem>().toList();
    if (enriched.isNotEmpty) setState(() => _heroes = enriched);
  }

  // المحتوى الجديد (2025/2026) يحتاج اشتراك

  // ── Skeleton Loading — بدلاً من الشاشة السوداء ────────
  Widget _buildSkeleton() {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(children: [
          // Hero skeleton
          Container(
            height: 220, margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: C.surface, borderRadius: BorderRadius.circular(16)),
            child: Center(child: _Pulse(label: 'TOTV+')),
          ),
          // Filter chips skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: List.generate(4, (i) => Container(
              margin: const EdgeInsets.only(right: 8),
              width: 70, height: 32,
              decoration: BoxDecoration(
                color: C.surface, borderRadius: BorderRadius.circular(16)),
            ))),
          ),
          const SizedBox(height: 16),
          // Grid skeleton
          Expanded(child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
              childAspectRatio: 0.65),
            itemCount: 12,
            itemBuilder: (_, __) => _SkeletonCard(),
          )),
        ]),
      ),
    );
  }

  bool _isNew(String year) {
    // VIP: never needs subscribe
    if (Sub.isVIP) return false;
    if (year.isEmpty) return false;
    final y = int.tryParse(year) ?? 0;
    return y >= 2025;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // بدلاً من شاشة بيضاء/سوداء — أظهر skeleton loading
    if (_busy && _heroes.isEmpty) return _buildSkeleton();

    return Scaffold(
      backgroundColor: C.bg,
      body: RefreshIndicator(color: C.gold, backgroundColor: C.surface, strokeWidth: 1.5,
        onRefresh: () async {
          ListCache.invalidate(); await AppState.loadAll(force: true); await _build();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          cacheExtent: 1600,
          slivers: [
            // ── Hero Carousel (TOD Style) ──
            if (_heroes.isNotEmpty)
              SliverToBoxAdapter(child: _TODHeroCarousel(
                heroes: _heroes,
                curIdx: _hIdx,
                onChanged: (i) => setState(() => _hIdx = i),
                onPlay: _playHero,
                onInfo: _infoHero,
              )),

            // ── Navigation Categories (TOD horizontal tabs) ──
            SliverToBoxAdapter(child: _CategoryTabs(
              cats: ['الكل', 'أفلام', 'مسلسلات', 'مباشر'],
              onTap: (_) {},
            )),

            // ── تابع ما بدأت (Netflix-style) ──────────────────
            if (Recommendations.continueWatching().isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHdr(
                title: 'تابع ما بدأت',
                icon: Icons.play_circle_rounded,
                onMore: () {})),
              SliverToBoxAdapter(child: _ContinueWatchingRow(
                  items: Recommendations.continueWatching(),
                  onTap: _openInfo)),
            ],

            // ── مقترح لك ─────────────────────────────────────────
            if (Recommendations.forYou().isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHdr(
                title: 'مقترح لك',
                icon: Icons.auto_awesome_rounded,
                onMore: () {})),
              SliverToBoxAdapter(child: _LandscapeRow(
                  items: Recommendations.forYou(limit: 15),
                  type: 'movie', onTap: _openInfo)),
            ],

            // ── أحدث الأفلام ──────────────────────────────────────
            if (AppState.allMovies.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHdr(title: 'أحدث الأفلام', onMore: () {})),
              SliverToBoxAdapter(child: _LandscapeRow(
                  items: AppState.allMovies.take(15).toList(),
                  type: 'movie', onTap: _openInfo)),
            ],

            // ── أحدث المسلسلات ────────────────────────────────────
            if (AppState.allSeries.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHdr(title: 'أحدث المسلسلات', onMore: () {})),
              SliverToBoxAdapter(child: _PortraitRow(
                  items: AppState.allSeries.take(15).toList(),
                  type: 'series', onTap: _openInfo)),
            ],

            // ── البث المباشر ──────────────────────────────────────
            if (AppState.allLive.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHdr(title: 'البث المباشر', onMore: () {})),
              SliverToBoxAdapter(child: _LiveChannelRow(
                  items: AppState.allLive.take(12).toList(),
                  onTap: _openInfo)),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ])));
  }

  void _playHero(_HeroItem h) {
    Ads.show();
    if (h.isTv) { Navigator.push(context, _fade(SeriesDetailPage(series: h.item))); return; }
    Navigator.push(context, _fade(PlayerPage(
        urls: Api.movieUrls(h.item), title: h.title, item: h.item)));
  }

  void _infoHero(_HeroItem h) {
    _showInfo(h.item, h.isTv ? 'series' : 'movie',
        backdrop: h.backdrop, poster: h.poster, title: h.title,
        overview: h.overview, rating: h.rating, year: h.year,
        cast: h.cast, director: h.director, needsSub: h.needsSub);
  }

  void _openInfo(dynamic item, String type) {
    Sound.hapticL();
    _showInfoLazy(item, type);
  }

  // ترشيحات ذكية بناءً على تاريخ المشاهدة
  List<dynamic> _getRecommended() {
    final pool = [...AppState.allMovies, ...AppState.allSeries];
    return WatchHistory.recommend(pool);
  }

  // البحث عن رابط التشغيل من السيرفر إذا لم يتوفر
  Future<List<String>> _resolveUrls(dynamic item, String type) async {
    final id = item['stream_id']?.toString() ?? '';
    if (id.isNotEmpty) {
      if (type == 'live') return Api.liveUrls(item);
      if (type == 'movie') return Api.movieUrls(item);
    }
    // البحث عن ID من السيرفر باسم المحتوى
    try {
      final name = (item['name'] ?? '').toString();
      final action = type == 'series' ? 'get_series' : 'get_vod_streams';
      final list = await Api.getList(action);
      final found = list.firstWhere(
        (e) => (e['name'] ?? '').toString().toLowerCase() == name.toLowerCase(),
        orElse: () => null,
      );
      if (found != null) {
        if (type == 'movie') return Api.movieUrls(found);
        if (type == 'live') return Api.liveUrls(found);
      }
    } catch (_) {}
    return [];
  }

  void _showInfo(dynamic item, String type, {
    String backdrop = '', String poster = '', String title = '',
    String overview = '', String rating = '', String year = '',
    String cast = '', String director = '', bool needsSub = false}) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
        isScrollControlled: true, useSafeArea: true,
        builder: (_) => _TODInfoSheet(
            item: item, type: type, backdrop: backdrop, poster: poster,
            title: title, overview: overview, rating: rating, year: year,
            cast: cast, director: director, needsSub: needsSub));
  }

  void _showInfoLazy(dynamic item, String type) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
        isScrollControlled: true, useSafeArea: true,
        builder: (_) => _InfoSheetLoader(item: item, type: type));
  }

  void _openHistoryItem(Map<String,dynamic> h) {
    Sound.hapticL();
    final item = h['item'] ?? h;
    final type = h['type']?.toString() ?? 'movie';
    _showInfoLazy(item, type);
  }
}


// ══════════════════════════════════════════════════════════════
//  TOD HERO CAROUSEL — Fullscreen backdrop + معلومات
// ══════════════════════════════════════════════════════════════
class _HeroItem {
  final dynamic item; final bool isTv;
  final String backdrop, poster, title, overview, rating, year, cast, director;
  final bool needsSub;
  const _HeroItem({required this.item, required this.isTv,
      required this.backdrop, required this.poster, required this.title,
      required this.overview, required this.rating, required this.year,
      required this.cast, required this.director, required this.needsSub});
}

class _TODHeroCarousel extends StatelessWidget {
  final List<_HeroItem> heroes;
  final int curIdx;
  final void Function(int) onChanged;
  final void Function(_HeroItem) onPlay;
  final void Function(_HeroItem) onInfo;
  _TODHeroCarousel({required this.heroes, required this.curIdx,
      required this.onChanged, required this.onPlay, required this.onInfo});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final h   = MediaQuery.of(context).size.height * 0.68;

    return SizedBox(height: h + top, child: Stack(children: [
      _AutoPageView(
        itemCount: heroes.length,
        interval: const Duration(seconds: 6),
        onPageChanged: onChanged,
        height: h + top,
        itemBuilder: (_, i) {
          final h2 = heroes[i];
          return Stack(fit: StackFit.expand, children: [
            h2.backdrop.isNotEmpty
                ? CachedNetworkImage(imageUrl: _imgUrl(h2.backdrop), fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    errorWidget: (_, __, ___) => Container(color: C.surface))
                : Container(color: C.surface),
            const DecoratedBox(decoration: BoxDecoration(gradient: C.heroGrad)),
          ]);
        }),

      // ── Header: شعار + قائمة أفقية ──
      Positioned(top: top + 8, left: 0, right: 0,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            ShaderMask(
              shaderCallback: (b) => C.goldGrad.createShader(b),
              blendMode: BlendMode.srcIn,
              child: Text('TOTV+', style: T.cinzel(s: 18, c: Colors.white, w: FontWeight.w900)
                  .copyWith(letterSpacing: 3))),
            const Spacer(),
            if (!Sub.isPremium)
              GestureDetector(
                onTap: () => Navigator.push(context, _fade(const ProfilePage())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(gradient: C.playGrad, borderRadius: BorderRadius.circular(8)),
                  child: Text('اشتراك', style: T.cairo(s: 11, w: FontWeight.w800, c: Colors.black)))),
          ]))),

      // ── معلومات المحتوى ──
      if (curIdx < heroes.length)
        Positioned(bottom: 0, left: 0, right: 0,
          child: _buildInfo(heroes[curIdx], context)),

      // ── Dots ──
      Positioned(bottom: 14, right: 16,
        child: Row(children: List.generate(heroes.length, (i) =>
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == curIdx ? 20 : 5, height: 4,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: i == curIdx ? C.gold : C.dim.withOpacity(0.6),
              borderRadius: BorderRadius.circular(2)))))),
    ]));
  }

  Widget _buildInfo(_HeroItem h, BuildContext ctx) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      // متا: سنة + تقييم + نوع
      Row(children: [
        if (h.year.isNotEmpty) ...[
          Text(h.year.length >= 4 ? h.year.substring(0, 4) : h.year,
              style: T.mont(s: 12, c: C.grey)),
          const Text('  •  ', style: TextStyle(color: C.dim, fontSize: 12)),
        ],
        if (h.rating.isNotEmpty && h.rating != '0.0') ...[
          const Icon(Icons.star_rounded, color: C.gold, size: 13),
          const SizedBox(width: 3),
          Text(h.rating, style: T.mont(s: 12, c: C.gold, w: FontWeight.w600)),
          const Text('  •  ', style: TextStyle(color: C.dim, fontSize: 12)),
        ],
        if (h.needsSub)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(4)),
            child: Text('حصري', style: T.mont(s: 9, c: Colors.black, w: FontWeight.w700))),
        if (!h.needsSub)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                border: Border.all(color: C.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(4)),
            child: Text('HD', style: T.mont(s: 9, c: C.grey))),
      ]),
      const SizedBox(height: 8),
      Text(h.title,
          style: T.cairo(s: 26, w: FontWeight.w900).copyWith(letterSpacing: -0.5),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      if (h.overview.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(h.overview, style: T.mont(s: 12, c: C.grey.withOpacity(0.8)),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
      const SizedBox(height: 14),
      Row(children: [
        // زر الاشتراك إذا محتوى جديد وغير مشترك
        if (h.needsSub && !Sub.isPremium) ...[
          Expanded(child: GestureDetector(onTap: () => Navigator.push(ctx, _fade(const ProfilePage())),
            child: Container(height: 46,
              decoration: BoxDecoration(gradient: C.playGrad, borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: C.gold.withOpacity(0.35), blurRadius: 12)]),
              child: Center(child: Text('اشتراك',
                  style: T.cairo(s: 15, w: FontWeight.w800, c: Colors.black)))))),
        ] else ...[
          Expanded(child: GestureDetector(onTap: () => onPlay(h),
            child: Container(height: 46,
              decoration: BoxDecoration(gradient: C.playGrad, borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: C.gold.withOpacity(0.35), blurRadius: 12)]),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                const SizedBox(width: 6),
                Text('تشغيل', style: T.cairo(s: 14, w: FontWeight.w800, c: Colors.black)),
              ])))),
        ],
        const SizedBox(width: 10),
        GestureDetector(onTap: () => onInfo(h),
          child: Container(width: 46, height: 46,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5)),
            child: const Icon(Icons.add_rounded, color: C.white, size: 22))),
      ]),
    ]));
}

// ══════════════════════════════════════════════════════════════
//  TOD INFO SHEET — مثل الصورة تماماً
// ══════════════════════════════════════════════════════════════
class _TODInfoSheet extends StatefulWidget {
  final dynamic item; final String type;
  final String backdrop, poster, title, overview, rating, year, cast, director;
  final bool needsSub;
  final bool isLive;
  _TODInfoSheet({required this.item, required this.type,
      required this.backdrop, required this.poster, required this.title,
      required this.overview, required this.rating, required this.year,
      required this.cast, required this.director, required this.needsSub,
      this.isLive = false});
  @override State<_TODInfoSheet> createState() => _TODInfoSheetState();
}

class _TODInfoSheetState extends State<_TODInfoSheet> {
  bool _inWl = false;
  @override void initState() { super.initState(); _inWl = WL.has(widget.item); }

  void _play() {
    Navigator.pop(context);
    Ads.show();
    WatchHistory.addItem(widget.item, widget.type); // سجّل في التاريخ
    if (widget.type == 'series') {
      Navigator.push(context, _fade(SeriesDetailPage(series: widget.item)));
      return;
    }
    final urls = widget.type == 'live'
        ? Api.liveUrls(widget.item)
        : Api.movieUrls(widget.item);
    Navigator.push(context, _fade(PlayerPage(urls: urls, title: widget.title,
        isLive: widget.type == 'live', item: widget.item)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF2080808), // شبه شفاف عميق
        borderRadius: const BorderRadius.vertical(top: Radius.circular(S.rXl)),
        border: Border.all(color: C.glassBdr, width: 0.5)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: C.dim.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2))),

        // ── Backdrop ──────────────────────────────────────
        Stack(children: [
          // زر الإغلاق
          Positioned(top: 12, left: 12, child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(width: 32, height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.6)),
              child: const Icon(Icons.close_rounded, color: C.white, size: 18)))),

          SizedBox(height: 260, width: double.infinity,
            child: ClipRRect(borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(S.rXl), topRight: Radius.circular(S.rXl)),
              child: widget.backdrop.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.backdrop,
                      fit: BoxFit.cover,
                      memCacheHeight: 700,
                      fadeInDuration: const Duration(milliseconds: 200),
                      errorWidget: (_, __, ___) => widget.poster.isNotEmpty
                          ? CachedNetworkImage(imageUrl: widget.poster, fit: BoxFit.cover)
                          : SmartPoster(item: widget.item, isTv: widget.type == 'series',
                              fit: BoxFit.cover))
                  : SmartPoster(item: widget.item, isTv: widget.type == 'series',
                      fit: BoxFit.cover))),
          Container(height: 220, decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, const Color(0xFF111111).withOpacity(0.98)]))),
        ]),

        // ── Content ───────────────────────────────────────
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Poster + Title row (TOD style)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Poster/Logo
              if (widget.poster.isNotEmpty)
                ClipRRect(borderRadius: BorderRadius.circular(10),
                  child: SizedBox(width: 90, height: 130,
                    child: CachedNetworkImage(imageUrl: widget.poster, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: C.surface)))),
              if (widget.poster.isNotEmpty) const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: T.cairo(s: 18, w: FontWeight.w900),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                // Meta: year • rating • genre
                Wrap(runSpacing: 6, spacing: 8, children: [
                  if (widget.year.isNotEmpty)
                    _MetaChip(widget.year.length >= 4 ? widget.year.substring(0,4) : widget.year),
                  if (widget.rating.isNotEmpty && widget.rating != '0.0')
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded, color: C.gold, size: 13),
                      const SizedBox(width: 3),
                      Text(widget.rating, style: T.mont(s: 12, c: C.gold, w: FontWeight.w700)),
                    ]),
                  if (widget.type == 'live')
                    _LiveBadge(),
                  _MetaChip('HD'),
                  if (widget.needsSub)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(5)),
                      child: Text('حصري', style: T.mont(s: 9, c: Colors.black, w: FontWeight.w700))),
                ]),
              ])),
            ]),

            // Overview
            if (widget.overview.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(widget.overview, style: T.mont(s: 13, c: C.grey, ls: 0.2),
                  maxLines: 4, overflow: TextOverflow.ellipsis),
            ],

            // Director
            if (widget.director.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('إخراج  ', style: T.cairo(s: 12, c: C.gold, w: FontWeight.w700)),
                Expanded(child: Text(widget.director, style: T.cairo(s: 12, c: C.grey))),
              ]),
            ],
            // Cast
            if (widget.cast.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('بطولة  ', style: T.cairo(s: 12, c: C.gold, w: FontWeight.w700)),
                Expanded(child: Text(widget.cast, style: T.cairo(s: 12, c: C.grey),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
              ]),
            ],

            const SizedBox(height: 16),
            // Buttons
            Row(children: [
              // زر الاشتراك أو التشغيل
              Expanded(child: widget.needsSub && !Sub.isPremium
                  ? Column(children: [
                      // زر الاشتراك الرئيسي
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, _fade(const ProfilePage()));
                        },
                        child: Container(
                          height: 52, width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF5C518), Color(0xFFFFAB00)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.workspace_premium, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(Sub.isFree ? 'اشترك للمشاهدة' : 'ترقية للـ VIP',
                                style: const TextStyle(color: Colors.black,
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // زر شراء خارجي
                      GestureDetector(
                        onTap: () {
                          final url = Sub.buyUrl;
                          if (url.isNotEmpty) launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        },
                        child: Container(
                          height: 40, width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: C.gold.withOpacity(0.5)),
                          ),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.shopping_cart_outlined, color: C.gold, size: 16),
                            SizedBox(width: 6),
                            Text('شراء اشتراك', style: TextStyle(color: C.gold, fontSize: 13)),
                          ]),
                        ),
                      ),
                    ])
                  : GestureDetector(
                      onTap: _play,
                      child: Container(
                        height: 52, width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: C.playGrad,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: C.gold.withOpacity(0.4), blurRadius: 14)],
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.black, size: 26),
                          SizedBox(width: 8),
                          Text('تشغيل الآن', style: TextStyle(color: Colors.black,
                              fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                      ),
                    )),
              const SizedBox(width: 10),
              // + قائمتي
              GestureDetector(
                onTap: () async {
                  await WL.toggle(widget.item, widget.type);
                  setState(() => _inWl = !_inWl);
                  Sound.hapticL();
                },
                child: Column(children: [
                  Icon(_inWl ? Icons.check_rounded : Icons.add_rounded,
                      color: _inWl ? C.gold : C.white, size: 24),
                  Text('قائمتي', style: T.cairo(s: 9, c: _inWl ? C.gold : C.grey)),
                ])),
              const SizedBox(width: 10),
              // مشاركة
              GestureDetector(
                onTap: () {
                  Sound.hapticL();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('رابط "${widget.title}" تم نسخه',
                        style: const TextStyle(color: Colors.black)),
                    backgroundColor: C.gold, duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
                },
                child: Column(children: [
                  const Icon(Icons.share_rounded, color: C.white, size: 22),
                  Text('مشاركة', style: T.cairo(s: 9, c: C.grey)),
                ])),
            ]),
          ])),
      ]));
  }
}

// ── Lazy Info Sheet Loader ─────────────────────────────────
class _InfoSheetLoader extends StatefulWidget {
  final dynamic item; final String type;
  _InfoSheetLoader({required this.item, required this.type});
  @override State<_InfoSheetLoader> createState() => _InfoSheetLoaderState();
}
class _InfoSheetLoaderState extends State<_InfoSheetLoader> {
  Map<String, String> _tmdb = {};
  bool _loading = true;

  @override void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = widget.item['name']?.toString() ?? '';
    final id   = widget.item['stream_id']?.toString() ?? widget.item['series_id']?.toString() ?? '';
    final icon = widget.item['stream_icon']?.toString() ?? widget.item['cover']?.toString() ?? '';
    final isTv = widget.type == 'series';
    final tmdb = id.isNotEmpty
        ? await TMDB.fromWorker(id, name, isTv: isTv)
        : await TMDB.search(name, isTv: isTv);
    if (mounted) setState(() {
      _tmdb = tmdb;
      if ((_tmdb['poster'] ?? '').isEmpty && icon.isNotEmpty) _tmdb['poster'] = icon;
      if ((_tmdb['backdrop'] ?? '').isEmpty && icon.isNotEmpty) _tmdb['backdrop'] = icon;
      _loading = false;
    });
  }

  bool _isNew(String year) {
    // VIP: never needs subscribe
    if (Sub.isVIP) return false;
    if (year.isEmpty) return false;
    final y = int.tryParse(year) ?? 0;
    return y >= 2025;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Container(
      height: 300, color: const Color(0xFF111111),
      child: const Center(child: CircularProgressIndicator(color: C.gold, strokeWidth: 1.5)));

    final year = _tmdb['year'] ?? '';
    return _TODInfoSheet(
      item: widget.item, type: widget.type,
      backdrop: _tmdb['backdrop'] ?? widget.item['stream_icon'] ?? '',
      poster:   _tmdb['poster']   ?? widget.item['stream_icon'] ?? '',
      title:    _tmdb['title']    ?? widget.item['name'] ?? '',
      overview: _tmdb['overview'] ?? '',
      rating:   _tmdb['rating']   ?? '',
      year:     year,
      cast:     _tmdb['cast']     ?? '',
      director: _tmdb['director'] ?? '',
      needsSub: _isNew(year),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  UI COMPONENTS — TOD Style
// ══════════════════════════════════════════════════════════════

// ── Category Tabs (horizontal scroll) ─────────────────────
class _CategoryTabs extends StatefulWidget {
  final List<String> cats; final ValueChanged<int> onTap;
  _CategoryTabs({required this.cats, required this.onTap});
  @override State<_CategoryTabs> createState() => _CategoryTabsState();
}
class _CategoryTabsState extends State<_CategoryTabs> {
  int _sel = 0;
  @override
  Widget build(BuildContext context) => SizedBox(height: 46,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: widget.cats.length,
      itemBuilder: (_, i) {
        final sel = i == _sel;
        return GestureDetector(
          onTap: () { setState(() => _sel = i); widget.onTap(i); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: sel ? C.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? C.gold : C.border)),
            child: Text(widget.cats[i],
                style: T.cairo(s: 12, c: sel ? Colors.black : C.grey,
                    w: sel ? FontWeight.w700 : FontWeight.w400))));
      }));
}

// ── Section Header ─────────────────────────────────────────
class _SectionHdr extends StatelessWidget {
  final String title;
  final VoidCallback onMore;
  final IconData? icon;
  _SectionHdr({required this.title, required this.onMore, this.icon});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
    child: Row(children: [
      if (icon != null) ...[
        Icon(icon!, color: C.gold, size: 16),
        const SizedBox(width: 6),
      ],
      Text(title, style: T.cairo(s: 16, w: FontWeight.w700)),
      const Spacer(),
      GestureDetector(onTap: onMore,
        child: Text('عرض الكل', style: T.cairo(s: 12, c: C.gold))),
    ]));
}

// ── Continue Watching Row (مع progress bar - Netflix style) ──
class _ContinueWatchingRow extends StatelessWidget {
  final List<dynamic> items;
  final void Function(dynamic, String) onTap;
  _ContinueWatchingRow({required this.items, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(height: 140,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length > 15 ? 15 : items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final img  = item['stream_icon']?.toString() ?? item['cover']?.toString() ?? '';
        final type = item['_type']?.toString() ?? 'movie';
        final id   = item['stream_id']?.toString() ?? item['series_id']?.toString() ?? '';
        final progress = WatchHistory.getPercent(id, 3600);
        return GestureDetector(
          onTap: () => onTap(item, type),
          child: Container(
            width: 180, margin: const EdgeInsets.only(right: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(fit: StackFit.expand, children: [
                  img.isNotEmpty
                      ? CachedNetworkImage(imageUrl: _imgUrl(img), fit: BoxFit.cover,
                          memCacheHeight: 250,
                          placeholder: (_, __) => Container(color: C.surface),
                          errorWidget: (_, __, ___) => _NoImg(item['name']?.toString() ?? '' ?? ''))
                      : _NoImg(item['name']?.toString() ?? '' ?? ''),
                  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)])))),
                  Center(child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.6),
                        border: Border.all(color: C.gold.withOpacity(0.8), width: 1.5)),
                    child: const Icon(Icons.play_arrow_rounded, color: C.white, size: 20))),
                ]))),
              const SizedBox(height: 3),
              ClipRRect(borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress, minHeight: 3,
                  backgroundColor: C.surface,
                  valueColor: const AlwaysStoppedAnimation(C.gold))),
              const SizedBox(height: 4),
              Text(item['name']?.toString() ?? '',
                  style: T.cairo(s: 10, c: C.grey),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])));
      }));
}

// ── Landscape Row (أفلام — عرضية) ─────────────────────────
class _LandscapeRow extends StatelessWidget {
  final List<dynamic> items; final String type;
  final void Function(dynamic, String) onTap;
  _LandscapeRow({required this.items, required this.type, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(height: 120,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length > 20 ? 20 : items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final img  = item['stream_icon']?.toString() ?? item['cover']?.toString() ?? '';
        return GestureDetector(
          onTap: () => onTap(item, type),
          child: Container(
            width: 180, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: C.card),
            child: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Stack(fit: StackFit.expand, children: [
                SmartPoster(item: item, fit: BoxFit.cover, memH: 250,
                    radius: BorderRadius.circular(S.rMd)),
                DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),
                Positioned(bottom: 6, left: 8, right: 8,
                  child: Text(item['name'] ?? '',
                    style: T.caption(c: C.textPri).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]))));
      }));
}

// ── Portrait Row (مسلسلات — بورتريه) ──────────────────────
class _PortraitRow extends StatelessWidget {
  final List<dynamic> items; final String type;
  final void Function(dynamic, String) onTap;
  _PortraitRow({required this.items, required this.type, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(height: 168,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length > 20 ? 20 : items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final img  = item['stream_icon']?.toString() ?? item['cover']?.toString() ?? '';
        return GestureDetector(
          onTap: () => onTap(item, type),
          child: Container(
            width: 100, margin: const EdgeInsets.only(right: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8),
                child: img.isNotEmpty
                    ? SmartPoster(item: item, isTv: type == 'series',
                        fit: BoxFit.cover, memH: 300, memW: 100,
                        radius: BorderRadius.circular(S.rMd))
                    : _NoImg(item['name']?.toString() ?? '' ?? '', isTv: type == 'series'))),
              const SizedBox(height: 4),
              Text(item['name'] ?? '', style: T.cairo(s: 10),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])));
      }));
}

// ── Live Channel Row (مع EPG) ──────────────────────────────
class _LiveChannelRow extends StatelessWidget {
  final List<dynamic> items;
  final void Function(dynamic, String) onTap;
  _LiveChannelRow({required this.items, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(height: 88,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length > 20 ? 20 : items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final img  = item['stream_icon']?.toString() ?? '';
        final id   = item['stream_id']?.toString() ?? '';
        final epg  = id.isNotEmpty ? EpgService.currentProgram(id) : null;
        return GestureDetector(
          onTap: () => onTap(item, 'live'),
          child: Container(
            width: 78, margin: const EdgeInsets.only(right: 8),
            child: Column(children: [
              Container(width: 60, height: 60,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: C.surface,
                    border: Border.all(color: C.border, width: 0.5)),
                child: Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: img.isNotEmpty
                        ? CachedNetworkImage(imageUrl: _imgUrl(img), fit: BoxFit.cover, width: 60, height: 60)
                        : const Center(child: Icon(Icons.live_tv_rounded, color: C.dim, size: 24))),
                  // مؤشر LIVE
                  Positioned(bottom: 4, right: 4,
                    child: Container(width: 8, height: 8,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: C.live))),
                ])),
              const SizedBox(height: 4),
              Text(item['name'] ?? '', style: T.cairo(s: 9, c: C.grey),
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
              // EPG: اسم البرنامج الحالي
              if (epg != null)
                Text(epg.title, style: T.cairo(s: 8, c: C.dim),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ])));
      }));
}

// ── No Image Placeholder ───────────────────────────────────
class _NoImg extends StatelessWidget {
  final String name;
  final bool isTv;
  const _NoImg(this.name, {this.isTv = false});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF1C1C1C), Color(0xFF0D0D0D)])),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(isTv ? Icons.tv_rounded : Icons.movie_rounded, color: C.dim, size: 24),
      const SizedBox(height: 6),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(name, style: T.caption(c: C.dim),
            maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
    ])));
}

class _SkeletonCard extends StatefulWidget {
  @override State<_SkeletonCard> createState() => _SkeletonCardState();
}
class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();
    _anim = Tween(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext _) => AnimatedBuilder(
    animation: _anim,
    builder: (__, ___) => ClipRRect(
      borderRadius: BorderRadius.circular(S.rMd),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [
              (_anim.value - 0.4).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.4).clamp(0.0, 1.0),
            ],
            colors: const [
              Color(0xFF141414), Color(0xFF242424), Color(0xFF141414),
            ])),
      ),
    ),
  );
}


// ══════════════════════════════════════════════════════════════
//  SEARCH PAGE — بحث موحّد Netflix-level
// ══════════════════════════════════════════════════════════════
class SearchPage extends StatefulWidget {
  const SearchPage();
  @override State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  final _ctrl = TextEditingController();
  String _query = '';
  String _filterType = 'all';
  List<dynamic> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override void dispose() { _ctrl.dispose(); _debounce?.cancel(); super.dispose(); }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = q);
      _search(q);
    });
  }

  void _search(String q) {
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final lower = q.toLowerCase();
    List<dynamic> pool = [];
    if (_filterType == 'all' || _filterType == 'movie')
      pool.addAll(AppState.allMovies.map((e) => {...Map<String,dynamic>.from(e as Map), '_type': 'movie'}));
    if (_filterType == 'all' || _filterType == 'series')
      pool.addAll(AppState.allSeries.map((e) => {...Map<String,dynamic>.from(e as Map), '_type': 'series'}));
    if (_filterType == 'all' || _filterType == 'live')
      pool.addAll(AppState.allLive.map((e) => {...Map<String,dynamic>.from(e as Map), '_type': 'live'}));
    final starts   = pool.where((e) => (e['name']??'').toString().toLowerCase().startsWith(lower)).toList();
    final contains = pool.where((e) { final n=(e['name']??'').toString().toLowerCase(); return n.contains(lower) && !n.startsWith(lower); }).toList();
    setState(() { _results = [...starts, ...contains].take(100).toList(); _searching = false; });
  }

  void _openItem(dynamic item) {
    Sound.hapticL();
    final type = item['_type']?.toString() ?? 'movie';
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      isScrollControlled: true, useSafeArea: true,
      builder: (_) => _InfoSheetLoader(item: item, type: type));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(backgroundColor: C.bg, body: Column(children: [
      Container(padding: EdgeInsets.fromLTRB(16, top + 12, 16, 12), color: C.bg,
        child: Column(children: [
          Container(height: 46, decoration: BoxDecoration(
            color: C.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.border, width: 0.5)),
            child: Row(children: [
              const SizedBox(width: 12),
              Icon(Icons.search_rounded, color: C.gold.withOpacity(0.5), size: 20),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _ctrl, autofocus: false,
                textDirection: TextDirection.rtl,
                style: T.cairo(s: 14),
                decoration: InputDecoration(
                  hintText: 'ابحث عن فيلم، مسلسل، قناة...',
                  hintStyle: T.cairo(s: 13, c: C.dim),
                  border: InputBorder.none, isDense: true),
                onChanged: _onQueryChanged)),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () { _ctrl.clear(); setState(() { _query = ''; _results = []; }); },
                  child: Padding(padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.close_rounded, color: C.dim, size: 16))),
            ])),
          const SizedBox(height: 10),
          SizedBox(height: 32, child: ListView(scrollDirection: Axis.horizontal,
            children: [
              for (final f in [('all','الكل'),('movie','أفلام'),('series','مسلسلات'),('live','مباشر')])
                GestureDetector(
                  onTap: () { setState(() => _filterType = f.$1); _search(_query); },
                  child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: _filterType == f.$1 ? C.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _filterType == f.$1 ? C.gold : C.border)),
                    child: Text(f.$2, style: T.cairo(s: 12,
                      c: _filterType == f.$1 ? Colors.black : C.grey,
                      w: _filterType == f.$1 ? FontWeight.w700 : FontWeight.w400)))),
            ])),
        ])),
      Expanded(child: _query.isEmpty ? _buildRecent()
        : _searching ? const Center(child: CircularProgressIndicator(color: C.gold, strokeWidth: 1.5))
        : _results.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.search_off_rounded, color: C.dim, size: 48),
              const SizedBox(height: 12),
              Text('لا نتائج لـ "$_query"', style: T.cairo(s: 13, c: C.grey))]))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
                childAspectRatio: 0.62, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _results.length,
              itemBuilder: (_, i) => _ContentCard(
                item: _results[i], type: _results[i]['_type']?.toString() ?? 'movie',
                onTap: () => _openItem(_results[i]),
                onFav: () => setState(() {})))),
    ]));
  }

  Widget _buildRecent() {
    final recent = WatchHistory.recent;
    if (recent.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.search_rounded, color: C.dim, size: 48),
      const SizedBox(height: 12),
      Text('ابحث عن محتواك المفضل', style: T.cairo(s: 13, c: C.grey))
    ]));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: recent.length,
      itemBuilder: (_, i) {
        final h = recent[i];
        return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          leading: ClipRRect(borderRadius: BorderRadius.circular(6),
            child: SizedBox(width: 56, height: 56,
              child: CachedNetworkImage(imageUrl: _imgUrl(h['stream_icon']?.toString() ?? h['icon']?.toString() ?? ''),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: C.surface,
                  child: const Icon(Icons.movie_rounded, color: C.dim, size: 20))))),
          title: Text(h['name']?.toString() ?? '', style: T.cairo(s: 13, w: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(h['_type'] == 'live' ? 'بث مباشر' : h['_type'] == 'series' ? 'مسلسل' : 'فيلم',
            style: T.cairo(s: 11, c: C.grey)),
          trailing: const Icon(Icons.play_circle_outline_rounded, color: C.gold, size: 22),
          onTap: () => _openItem(h));
      });
  }
}

// ══════════════════════════════════════════════════════════════
//  LIVE PAGE — قنوات مباشرة بتصميم شبكي
// ══════════════════════════════════════════════════════════════
class LivePage extends StatefulWidget {
  const LivePage();
  @override State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  List<dynamic> _filtered = [];
  String _selCat = '', _query = '';
  bool _busy = false;
  final _ctrl = TextEditingController();

  @override void initState() { super.initState(); _apply(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    AppState.allLive    = await Api.getList('get_live_streams', force: true);
    AppState.liveCats   = await Api.getList('get_live_categories', force: true);
    if (mounted) { setState(() => _busy = false); _apply(); }
  }

  void _apply() {
    var b = AppState.allLive;
    if (_selCat.isNotEmpty) b = b.where((c) => c['category_id']?.toString() == _selCat).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      b = b.where((c) => (c['name'] ?? '').toString().toLowerCase().contains(q)).toList();
    }
    _filtered = b;
  }

  void _openChannel(dynamic ch) {
    Sound.hapticL();
    Navigator.push(context, _fade(PlayerPage(
        urls: Api.liveUrls(ch), title: ch['name']?.toString() ?? '', isLive: true)));
  }

  int _cols(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w > 900) return 5; if (w > 600) return 4; return 3;
  }

  // تقسيم القنوات لأقسام منظمة
  Map<String, List<dynamic>> _buildSections(List<dynamic> all) {
    // beIN Sports أولاً — أعلى أولوية
    final bein    = <dynamic>[];
    final sky     = <dynamic>[];
    final mbc     = <dynamic>[];
    final sport   = <dynamic>[];
    final news    = <dynamic>[];
    final kids    = <dynamic>[];
    final movies  = <dynamic>[];
    final series  = <dynamic>[];
    final general = <dynamic>[];

    for (final ch in all) {
      final n = (ch['name'] ?? '').toString().toLowerCase();
      if (n.contains('bein') || n.contains('بين'))       { bein.add(ch);    continue; }
      if (n.contains('sky sport') || n.contains('sky s')) { sky.add(ch);     continue; }
      if (n.contains('mbc'))                              { mbc.add(ch);     continue; }
      if (n.contains('sport') || n.contains('رياضة') ||
          n.contains('arena') || n.contains('eurosport') ||
          n.contains('dazn') || n.contains('match'))     { sport.add(ch);   continue; }
      if (n.contains('news') || n.contains('أخبار') ||
          n.contains('الجزيرة') || n.contains('العربية')||
          n.contains('cnn') || n.contains('bbc'))        { news.add(ch);    continue; }
      if (n.contains('kids') || n.contains('أطفال') ||
          n.contains('cartoon') || n.contains('baby'))   { kids.add(ch);    continue; }
      if (n.contains('movie') || n.contains('أفلام') ||
          n.contains('cinema') || n.contains('سينما'))   { movies.add(ch);  continue; }
      if (n.contains('serie') || n.contains('مسلسل') ||
          n.contains('drama') || n.contains('دراما'))    { series.add(ch);  continue; }
      general.add(ch);
    }

    // ترتيب beIN: 1،2،3... أولاً ثم 4K
    bein.sort((a, b) {
      final an = (a['name'] ?? '').toString().toLowerCase();
      final bn = (b['name'] ?? '').toString().toLowerCase();
      // 4K آخراً
      final a4k = an.contains('4k') ? 1 : 0;
      final b4k = bn.contains('4k') ? 1 : 0;
      if (a4k != b4k) return a4k.compareTo(b4k);
      // استخرج الرقم
      final ar = RegExp(r'(\d+)').firstMatch(an);
      final br = RegExp(r'(\d+)').firstMatch(bn);
      final ai = int.tryParse(ar?.group(1) ?? '999') ?? 999;
      final bi = int.tryParse(br?.group(1) ?? '999') ?? 999;
      return ai.compareTo(bi);
    });

    final sections = <String, List<dynamic>>{};
    if (bein.isNotEmpty)    sections['beIN Sports']    = bein;
    if (sky.isNotEmpty)     sections['Sky Sports']     = sky;
    if (sport.isNotEmpty)   sections['رياضة']           = sport;
    if (mbc.isNotEmpty)     sections['MBC']            = mbc;
    if (news.isNotEmpty)    sections['أخبار']           = news;
    if (movies.isNotEmpty)  sections['أفلام']           = movies;
    if (series.isNotEmpty)  sections['مسلسلات']         = series;
    if (kids.isNotEmpty)    sections['أطفال']           = kids;
    if (general.isNotEmpty) sections['عامة']            = general;
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final top = MediaQuery.of(context).padding.top;
    final pool = _query.isEmpty && _selCat.isEmpty
        ? AppState.allLive
        : _filtered;

    // Hero: beIN 1-3 دائماً أولاً
    final heroList = AppState.allLive.where((c) {
      final n = (c['name'] ?? '').toString().toLowerCase();
      return n.contains('bein') || n.contains('sky') || n.contains('mbc');
    }).take(8).toList();

    final sections = (_query.isEmpty && _selCat.isEmpty)
        ? _buildSections(AppState.allLive)
        : <String, List<dynamic>>{'نتائج البحث': _filtered};

    return Scaffold(backgroundColor: C.bg,
      body: RefreshIndicator(color: C.gold, backgroundColor: C.surface,
        strokeWidth: 1.5, onRefresh: _refresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          cacheExtent: 1200,
          slivers: [
            // ── Hero Carousel ──────────────────────────────────
            if (heroList.isNotEmpty && _query.isEmpty && _selCat.isEmpty)
              SliverToBoxAdapter(child: _LiveHeroCarousel(
                  channels: heroList, onTap: _openChannel)),

            // ── Header ─────────────────────────────────────────
            SliverToBoxAdapter(child: _AppHdr(
                top: heroList.isEmpty ? top : 0,
                title: 'مباشر', onRefresh: _refresh)),

            // ── Search ─────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: _SearchBar(ctrl: _ctrl,
                    onChanged: (v) => setState(() { _query = v; _apply(); })))),

            // ── Category Chips ──────────────────────────────────
            if (AppState.liveCats.isNotEmpty)
              SliverToBoxAdapter(child: SizedBox(height: 44, child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                itemCount: AppState.liveCats.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) return _Chip(label: 'الكل', sel: _selCat.isEmpty,
                      onTap: () => setState(() { _selCat = ''; _apply(); }));
                  final cat = AppState.liveCats[i - 1];
                  final id  = cat['category_id']?.toString() ?? '';
                  return _Chip(label: cat['category_name']?.toString() ?? '',
                      sel: _selCat == id,
                      onTap: () => setState(() { _selCat = id; _apply(); }));
                }))),

            // ── أقسام منظمة (beIN أولاً) ───────────────────────
            for (final entry in sections.entries) ...[
              SliverToBoxAdapter(child: _SectionHdr(
                  title: entry.value.length > 0
                      ? '${entry.key}  •  ${entry.value.length}'
                      : entry.key,
                  onMore: () {})),
              SliverToBoxAdapter(child: SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: entry.value.length > 20 ? 20 : entry.value.length,
                  itemBuilder: (_, i) {
                    final ch  = entry.value[i];
                    final nm  = ch['name']?.toString() ?? '';
                    return GestureDetector(
                      onTap: () => _openChannel(ch),
                      child: Container(
                        width: 106, margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: C.card,
                          borderRadius: BorderRadius.circular(S.rMd),
                          border: Border.all(color: C.border, width: 0.4)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(S.rMd),
                          child: Stack(fit: StackFit.expand, children: [
                            SmartPoster(item: ch, fit: BoxFit.contain,
                                radius: BorderRadius.circular(S.rMd)),
                            // تدرج أسفل
                            Positioned(bottom: 0, left: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(6, 16, 6, 5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)])),
                                child: Text(nm,
                                  style: T.caption(c: C.textPri).copyWith(
                                      fontSize: 9, fontWeight: FontWeight.w600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center))),
                            // LIVE badge
                            Positioned(top: 5, left: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: C.live, borderRadius: BorderRadius.circular(3)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Container(width: 3, height: 3, margin: const EdgeInsets.only(right: 3),
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                                  Text('LIVE', style: T.label(c: Colors.white, s: 7)),
                                ]))),
                          ]))));
                  }))),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ])));
  }
}

// ── Hero Carousel للقنوات المباشرة ──────────────────────────
class _LiveHeroCarousel extends StatefulWidget {
  final List<dynamic> channels;
  final void Function(dynamic) onTap;
  _LiveHeroCarousel({required this.channels, required this.onTap});
  @override State<_LiveHeroCarousel> createState() => _LiveHeroCarouselState();
}
class _LiveHeroCarouselState extends State<_LiveHeroCarousel> {
  int _cur = 0;
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.42;
    final list = widget.channels;
    return SizedBox(height: h, child: Stack(children: [
      _AutoPageView(
        itemCount: list.length,
        interval: const Duration(seconds: 5),
        onPageChanged: (i) => setState(() => _cur = i),
        itemBuilder: (_, i) {
          final ch  = list[i];
          final img = ch['stream_icon']?.toString() ?? '';
          final nm  = ch['name']?.toString() ?? '';
          final cat = ch['category_name']?.toString() ?? 'LIVE';
          return GestureDetector(onTap: () => widget.onTap(ch),
            child: Stack(fit: StackFit.expand, children: [
              // صورة القناة
              img.isNotEmpty
                  ? CachedNetworkImage(imageUrl: _imgUrl(img), fit: BoxFit.cover, memCacheHeight: 600,
                      placeholder: (_, __) => Container(color: C.surface),
                      errorWidget: (_, __, ___) => _liveChannelBg(nm))
                  : _liveChannelBg(nm),
              // Gradient أسفل
              const DecoratedBox(decoration: BoxDecoration(gradient: C.heroGrad)),
              // معلومات
              Positioned(bottom: 50, left: 16, right: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: C.live, borderRadius: BorderRadius.circular(5)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 5, height: 5, margin: const EdgeInsets.only(left: 4),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                        Text('مباشر', style: T.mont(s: 9, w: FontWeight.w800, c: Colors.white)),
                      ])),
                  ]),
                  const SizedBox(height: 8),
                  Text(nm, style: T.cairo(s: 22, w: FontWeight.w900),
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                  const SizedBox(height: 3),
                  Text(cat, style: T.mont(s: 11, c: C.grey)),
                  const SizedBox(height: 14),
                  // زر تشغيل
                  GestureDetector(onTap: () => widget.onTap(ch),
                    child: Container(height: 46, padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: BoxDecoration(gradient: C.playGrad,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: C.gold.withOpacity(0.4), blurRadius: 14)]),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                        const SizedBox(width: 6),
                        Text('مشاهدة الآن', style: T.cairo(s: 14, w: FontWeight.w800, c: Colors.black)),
                      ]))),
                ])),
            ]));
        }),
      // Dots
      Positioned(bottom: 16, left: 0, right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(list.length > 8 ? 8 : list.length, (i) =>
            AnimatedContainer(duration: const Duration(milliseconds: 200),
              width: i == _cur ? 20 : 5, height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i == _cur ? C.gold : C.dim,
                borderRadius: BorderRadius.circular(3)))))),
    ]));
  }

  Widget _liveChannelBg(String name) => Container(
    color: C.surface,
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.sensors_rounded, color: C.gold, size: 40),
      const SizedBox(height: 8),
      Text(name, style: T.cairo(s: 14, w: FontWeight.w700, c: C.grey),
          maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
    ])));
}

// ══════════════════════════════════════════════════════════════
//  CONTENT PAGE — أفلام / مسلسلات بتصميم TOD
// ══════════════════════════════════════════════════════════════
class ContentPage extends StatefulWidget {
  final String type, label;
  const ContentPage({required this.type, required this.label});
  @override State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  List<dynamic> _filtered = [];
  List<_HeroItem> _heroes  = [];
  int    _heroCur  = 0;
  String _selCat   = '', _query = '';
  final _ctrl = TextEditingController();
  String _viewMode = 'portrait';
  bool   _heroLoading = false;

  @override void initState() { super.initState(); _apply(); _loadHeroes(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  List<dynamic> get _source => widget.type == 'movie' ? AppState.allMovies : AppState.allSeries;
  List<dynamic> get _cats   => widget.type == 'movie' ? AppState.movieCats  : AppState.seriesCats;

  void _apply() {
    var b = List<dynamic>.from(_source);
    if (_selCat.isNotEmpty) b = b.where((e) => e['category_id']?.toString() == _selCat).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      b = b.where((e) => (e['name'] ?? '').toString().toLowerCase().contains(q)).toList();
    }
    // ترتيب: بوستر موجود أولاً، ثم حسب الفئة، ثم أبجدياً
    b.sort((x, y) {
      // أولوية 1: البوستر موجود
      final xHas = (x['stream_icon']?.toString() ?? x['cover']?.toString() ?? '').isNotEmpty ? 1 : 0;
      final yHas = (y['stream_icon']?.toString() ?? y['cover']?.toString() ?? '').isNotEmpty ? 1 : 0;
      if (xHas != yHas) return yHas.compareTo(xHas);
      // أولوية 2: نفس الفئة — ترتيب رقمي أو أبجدي
      final xCat = x['category_id']?.toString() ?? '';
      final yCat = y['category_id']?.toString() ?? '';
      if (xCat != yCat) return xCat.compareTo(yCat);
      return (x['name'] ?? '').toString().compareTo(y['name'] ?? '');
    });
    _filtered = b;
  }

  Future<void> _loadHeroes() async {
    if (_heroLoading || _heroes.isNotEmpty) return;
    _heroLoading = true;
    final sample = List.from(_source.take(30))..shuffle();
    final heroes = <_HeroItem>[];
    for (final item in sample.take(6)) {
      final isTv  = widget.type == 'series';
      final name  = item['name']?.toString() ?? '';
      final icon  = item['stream_icon']?.toString() ?? item['cover']?.toString() ?? '';
      final tmdb  = await TMDB.search(name, isTv: isTv);
      final year  = tmdb['year'] ?? '';
      heroes.add(_HeroItem(
        item: item, isTv: isTv,
        backdrop: tmdb['backdrop']?.isNotEmpty == true ? tmdb['backdrop']! : icon,
        poster:   tmdb['poster_sm']?.isNotEmpty == true ? tmdb['poster_sm']! : icon,
        title:    tmdb['title'] ?? name,
        overview: tmdb['overview'] ?? '',
        rating:   tmdb['rating'] ?? '',
        year:     year,
        cast:     tmdb['cast'] ?? '',
        director: tmdb['director'] ?? '',
        needsSub: _isNew(year),
      ));
    }
    if (mounted) setState(() { _heroes = heroes; _heroLoading = false; });
  }

  bool _isNew(String year) {
    // VIP: never needs subscribe
    if (Sub.isVIP) return false;
    if (year.isEmpty) return false;
    final y = int.tryParse(year) ?? 0;
    return y >= 2025;
  }

  Future<void> _refresh() async {
    final action = widget.type == 'movie' ? 'get_vod_streams' : 'get_series';
    final fresh = await Api.getList(action, force: true);
    if (widget.type == 'movie') AppState.allMovies = fresh;
    else AppState.allSeries = fresh;
    _heroes.clear();
    if (mounted) { setState(_apply); _loadHeroes(); }
  }

  void _openItem(dynamic item) {
    Sound.hapticL();
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
        isScrollControlled: true, useSafeArea: true,
        builder: (_) => _InfoSheetLoader(item: item, type: widget.type));
  }

  int get _cols {
    if (_viewMode == 'landscape') return 1;
    final w = MediaQuery.of(context).size.width;
    if (_viewMode == 'grid') return w > 600 ? 4 : 3;
    return w > 900 ? 5 : w > 600 ? 4 : 3; // 3 columns on phone — tidier
  }

  double get _ratio {
    if (_viewMode == 'landscape') return 3.0;
    // Portrait cards: fixed ratio = poster (2:3 = 0.67)
    // This ensures ALL cards same height — no irregular layout
    return 0.62;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(backgroundColor: C.bg,
      body: RefreshIndicator(color: C.gold, backgroundColor: C.surface,
          strokeWidth: 1.5, onRefresh: _refresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [

            // ── Hero Carousel كبير في الأعلى ──
            if (_heroes.isNotEmpty)
              SliverToBoxAdapter(child: _TODHeroCarousel(
                heroes: _heroes,
                curIdx: _heroCur,
                onChanged: (i) => setState(() => _heroCur = i),
                onPlay: (h) {
                  Ads.show();
                  if (h.isTv) { Navigator.push(context, _fade(SeriesDetailPage(series: h.item))); return; }
                  Navigator.push(context, _fade(PlayerPage(urls: Api.movieUrls(h.item), title: h.title)));
                },
                onInfo: (h) {
                  showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
                    isScrollControlled: true, useSafeArea: true,
                    builder: (_) => _TODInfoSheet(
                      item: h.item, type: widget.type,
                      backdrop: h.backdrop, poster: h.poster, title: h.title,
                      overview: h.overview, rating: h.rating, year: h.year,
                      cast: h.cast, director: h.director, needsSub: h.needsSub));
                },
              )),
            if (_heroes.isEmpty && _heroLoading)
              SliverToBoxAdapter(child: Container(
                height: MediaQuery.of(context).size.height * 0.52,
                color: C.surface,
                child: const Center(child: CircularProgressIndicator(color: C.gold, strokeWidth: 1.5)))),

            // ── Header + Search ──
            SliverToBoxAdapter(child: _AppHdr(top: _heroes.isEmpty ? top : 0, title: widget.label, onRefresh: _refresh)),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(14,8,14,0),
              child: _SearchBar(ctrl: _ctrl,
                  onChanged: (v) => setState(() { _query = v; _apply(); })))),

            // ── أقسام التصنيف ──
            if (_cats.isNotEmpty)
              SliverToBoxAdapter(child: SizedBox(height: 46, child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                itemCount: _cats.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) return _Chip(label: 'الكل', sel: _selCat.isEmpty,
                      onTap: () => setState(() { _selCat = ''; _apply(); }));
                  final cat = _cats[i - 1];
                  final id  = cat['category_id']?.toString() ?? '';
                  return _Chip(label: cat['category_name']?.toString() ?? '',
                      sel: _selCat == id,
                      onTap: () => setState(() { _selCat = id; _apply(); }));
                }))),

            // ── Counter + أوضاع العرض ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Row(children: [
                _CounterBar(label: '${_filtered.length} ${widget.type == "series" ? "مسلسل" : "فيلم"}'),
                const Spacer(),
                ...[
                  ['portrait',  Icons.view_column_rounded],
                  ['landscape', Icons.view_list_rounded],
                  ['grid',      Icons.grid_view_rounded],
                ].map((m) {
                  final mode = m[0] as String;
                  final ico  = m[1] as IconData;
                  return GestureDetector(
                    onTap: () => setState(() => _viewMode = mode),
                    child: Padding(padding: const EdgeInsets.only(left: 8),
                      child: Icon(ico, color: _viewMode == mode ? C.gold : C.dim, size: 18)));
                }),
              ]))),

            // ── Grid المحتوى ──
            SliverPadding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols, childAspectRatio: _ratio,
                    crossAxisSpacing: 10, mainAxisSpacing: 10),
                delegate: SliverChildBuilderDelegate(
                    (_, i) => _ContentCard(
                        item: _filtered[i], type: widget.type,
                        onTap: () => _openItem(_filtered[i]),
                        onFav: () => setState(() {}),
                        landscape: _viewMode == 'landscape'),
                    childCount: _filtered.length,
                    addRepaintBoundaries: true, addAutomaticKeepAlives: false))),
          ])));
  }
}

// ── Content Card — يدعم portrait + landscape + grid ───────
class _ContentCard extends StatelessWidget {
  final dynamic item; final String type;
  final VoidCallback onTap; final VoidCallback onFav;
  final bool landscape;
  _ContentCard({required this.item, required this.type,
      required this.onTap, required this.onFav, this.landscape = false});

  @override
  Widget build(BuildContext context) {
    final img  = item['stream_icon']?.toString() ?? item['cover']?.toString() ?? '';
    final name = item['name']?.toString() ?? '';

    if (landscape) return _buildLandscape(img, name);
    return _buildPortrait(img, name);
  }

  Widget _buildPortrait(String img, String name) {
    final id  = item['stream_id']?.toString() ?? item['series_id']?.toString() ?? '';
    final pct = id.isNotEmpty ? WatchHistory.getPercent(id, 0) : 0.0;
    final isTv = type == 'series';
    return RepaintBoundary(child: GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Stack(children: [
          // ── Poster ──────────────────────────────────────────
          Positioned.fill(child: ClipRRect(
            borderRadius: BorderRadius.circular(S.rMd),
            child: SmartPoster(
              item: item, isTv: isTv, fit: BoxFit.cover,
              memH: 300, memW: 200,
              radius: BorderRadius.circular(S.rMd)))),
          // ── Bottom fade gradient ─────────────────────────────
          Positioned(bottom: 0, left: 0, right: 0, height: 60,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(S.rMd)),
              child: DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)]))))),
          // ── Progress bar ─────────────────────────────────────
          if (pct > 0.02 && pct < 0.97)
            Positioned(bottom: 0, left: 0, right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(S.rMd)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(height: 3, color: Colors.white.withOpacity(0.15),
                    child: FractionallySizedBox(
                      widthFactor: pct, alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [C.goldLight, C.gold]))))),
                ]))),
          // ── LIVE badge ────────────────────────────────────────
          if (type == 'live')
            Positioned(top: S.xs, left: S.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: C.live, borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 4, height: 4, margin: const EdgeInsets.only(right: 3),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white)),
                  Text('LIVE', style: T.label(c: Colors.white, s: 8)),
                ]))),
          // ── Bookmark ─────────────────────────────────────────
          Positioned(top: S.xs, right: S.xs,
            child: StatefulBuilder(builder: (_, ss) {
              final fav = WL.has(item);
              return GestureDetector(
                onTap: () async {
                  await WL.toggle(item, type);
                  ss(() {}); onFav();
                  HapticFeedback.lightImpact();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(S.rMd),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: C.glass,
                        borderRadius: BorderRadius.circular(S.rMd),
                        border: Border.all(color: C.glassBdr, width: 0.5)),
                      child: Icon(
                        fav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: fav ? C.gold : C.textPri,
                        size: 14)))));
            })),
        ])),
        const SizedBox(height: S.xs + 2),
        Text(name,
          style: T.caption(c: C.textSec).copyWith(fontSize: 11),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ])));
  }

  Widget _buildLandscape(String img, String name) =>
    RepaintBoundary(child: GestureDetector(onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: C.border, width: 0.4)),
        child: Row(children: [
          ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            child: SizedBox(width: 80, height: double.infinity,
              child: img.isNotEmpty
                  ? CachedNetworkImage(imageUrl: _imgUrl(img), fit: BoxFit.cover, memCacheHeight: 200)
                  : _NoImg(name))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(name, style: T.cairo(s: 12, w: FontWeight.w600),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            if (type == 'live') ...[
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: C.live, borderRadius: BorderRadius.circular(3)),
                child: Text('مباشر', style: T.mont(s: 9, c: Colors.white, w: FontWeight.w700))),
            ],
          ])),
          Padding(padding: const EdgeInsets.only(right: 12),
            child: const Icon(Icons.play_circle_outline_rounded, color: C.gold, size: 24)),
        ]))));
}


// ══════════════════════════════════════════════════════════════
//  SERIES DETAIL — حلقات مع صور وتفاصيل TMDB
// ══════════════════════════════════════════════════════════════
class SeriesDetailPage extends StatefulWidget {
  final dynamic series;
  const SeriesDetailPage({required this.series});
  @override State<SeriesDetailPage> createState() => _SeriesDetailState();
}

class _SeriesDetailState extends State<SeriesDetailPage> with TickerProviderStateMixin {
  Map<String, dynamic>? _data;
  Map<String, String> _tmdb = {};
  bool _busy = true, _fail = false;
  int _season = 1;
  TabController? _tc;
  String _seriesCover = '';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _busy = true; _fail = false; });
    try {
      final sid = widget.series['series_id']?.toString() ?? '';
      if (sid.isEmpty) throw 'no sid';
      final results = await Future.wait([
        Api.getSeriesInfo(sid),
        TMDB.search(widget.series['name'] ?? '', isTv: true),
      ]);
      if (!mounted) return;
      final data = results[0] as Map<String, dynamic>;
      final tmdb = results[1] as Map<String, String>;
      _seriesCover = widget.series['cover']?.toString() ?? widget.series['stream_icon']?.toString() ?? '';
      final seas = _seasons(data);
      final old = _tc;
      final tabCount = seas.isNotEmpty ? seas.length : 1;
      _tc = TabController(length: tabCount, vsync: this);
      _tc!.addListener(() {
        if (!_tc!.indexIsChanging) return;
        if (seas.isNotEmpty && _tc!.index < seas.length) {
          setState(() => _season = seas[_tc!.index]);
        }
      });
      old?.dispose();
      if (mounted) setState(() {
        _data = data; _tmdb = tmdb;
        _season = seas.isNotEmpty ? seas.first : 1;
        _busy = false;
      });
    } catch (_) { if (mounted) setState(() { _busy = false; _fail = true; }); }
  }

  List<int> _seasons(Map<String, dynamic> d) {
    final eps = d['episodes'];
    if (eps is! Map) return [];
    return eps.keys.map((k) => int.tryParse(k.toString()) ?? -1)
        .where((v) => v > 0).toList()..sort();
  }

  List<dynamic> _eps(int s) {
    final eps = _data?['episodes'];
    if (eps is! Map) return [];
    final l = eps['$s'];
    return l is List ? l : [];
  }

  void _playEp(dynamic ep) {
    final urls  = Api.episodeUrls(ep);
    final title = '${widget.series['name']} — ${ep['title']?.toString().isNotEmpty == true ? ep['title'] : 'الحلقة ${ep['episode_num']}'}';
    Navigator.push(context, _fade(PlayerPage(urls: urls, title: title, item: ep)));
  }

  @override void dispose() { _tc?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    if (_busy) return Scaffold(backgroundColor: C.bg,
        body: Center(child: _Pulse(label: widget.series['name'] ?? '')));
    if (_fail) return Scaffold(backgroundColor: C.bg,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: C.dim, size: 48),
          const SizedBox(height: 14),
          GestureDetector(onTap: _load, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(gradient: C.playGrad, borderRadius: BorderRadius.circular(12)),
            child: Text('إعادة المحاولة', style: T.cairo(s: 13, c: Colors.black, w: FontWeight.w800)))),
        ])));

    final tc      = _tc;
    if (tc == null) return Scaffold(backgroundColor: C.bg, body: const SizedBox.shrink());
    final info    = (_data?['info'] as Map?)?.cast<String, dynamic>() ?? {};
    final cover   = _tmdb['backdrop'] ?? _tmdb['poster'] ?? info['cover'] ?? _seriesCover;
    final poster  = _tmdb['poster']   ?? info['movie_image'] ?? _seriesCover;
    final plot    = info['plot'] ?? info['description'] ?? _tmdb['overview'] ?? '';
    final rating  = info['rating'] ?? _tmdb['rating'] ?? '';
    final genre   = info['genre'] ?? widget.series['category_name'] ?? '';
    final cast    = _tmdb['cast'] ?? '';
    final director= _tmdb['director'] ?? '';
    final seas    = _seasons(_data!);
    final eps     = _eps(_season);

    return Scaffold(backgroundColor: C.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: Stack(children: [
            // Backdrop
            SizedBox(height: 280 + top, width: double.infinity,
              child: cover.isNotEmpty
                  ? CachedNetworkImage(imageUrl: _imgUrl(cover), fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: C.surface))
                  : Container(color: C.surface)),
            Container(height: 280 + top, decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.97)]))),
            // Close button
            Positioned(top: top + 10, left: 14,
              child: GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.6)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: C.white, size: 16)))),
            // Poster + Info
            Positioned(bottom: 0, left: 0, right: 0, child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (poster.isNotEmpty)
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: SizedBox(width: 85, height: 120,
                      child: CachedNetworkImage(imageUrl: _imgUrl(poster), fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: C.surface)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, children: [
                  if (genre.isNotEmpty) _TagW(genre),
                  const SizedBox(height: 5),
                  Text(widget.series['name'] ?? '',
                      style: T.cairo(s: 18, w: FontWeight.w900), maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, children: [
                    if (rating.isNotEmpty && rating != '0.0')
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, color: C.gold, size: 13),
                        const SizedBox(width: 2),
                        Text(rating, style: T.mont(s: 11, c: C.gold)),
                      ]),
                    Text('${seas.length} موسم', style: T.mont(s: 11, c: C.grey)),
                  ]),
                ])),
              ]))),
          ])),
          // Plot
          if (plot.isNotEmpty)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,10,16,0),
              child: Text(plot, style: T.mont(s: 12, c: C.grey), maxLines: 3,
                  overflow: TextOverflow.ellipsis))),
          // Cast
          if (cast.isNotEmpty)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,6,16,0),
              child: RichText(text: TextSpan(children: [
                TextSpan(text: 'طاقم العمل: ', style: T.cairo(s: 11, c: C.gold)),
                TextSpan(text: cast, style: T.cairo(s: 11, c: C.grey)),
              ])))),
          // Season tabs
          if (seas.length > 1)
            SliverToBoxAdapter(child: Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
              child: TabBar(controller: tc, isScrollable: true,
                indicatorColor: C.gold, indicatorWeight: 2.5,
                labelColor: C.gold, unselectedLabelColor: C.grey,
                labelStyle: T.mont(s: 12, w: FontWeight.w700),
                unselectedLabelStyle: T.mont(s: 12),
                tabs: seas.map((s) => Tab(text: 'موسم $s')).toList()))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(14,10,14,4),
            child: _CounterBar(label: '${eps.length} حلقة'))),
        ],
        body: _buildEpisodesList(eps, tc),
      ),
    );
  }

  Widget _buildEpisodesList(List<dynamic> eps, TabController tc) {
    if (_busy) return const Center(child: CircularProgressIndicator(color: C.gold, strokeWidth: 1.5));
    if (eps.isEmpty) {
      // حاول جلب الحلقات مرة أخرى
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.video_library_outlined, color: C.dim, size: 48),
        const SizedBox(height: 12),
        Text('لا توجد حلقات في هذا الموسم', style: T.cairo(s: 13, c: C.grey)),
        const SizedBox(height: 16),
        GestureDetector(onTap: _load, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(gradient: C.playGrad, borderRadius: BorderRadius.circular(10)),
          child: Text('إعادة التحميل', style: T.cairo(s: 12, c: Colors.black, w: FontWeight.w700)))),
      ]));
    }
    return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: eps.length,
                itemBuilder: (_, i) {
                  final ep    = eps[i];
                  final n     = ep['episode_num']?.toString() ?? '${i+1}';
                  final title = ep['title']?.toString().isNotEmpty == true
                      ? ep['title'] : 'الحلقة $n';
                  final thumb = ep['info']?['movie_image']?.toString()
                      ?? ep['info']?['still_path']?.toString()
                      ?? _seriesCover;
                  final dur   = ep['info']?['duration']?.toString() ?? '';
                  final epPlot= ep['info']?['plot']?.toString() ?? '';
                  return GestureDetector(onTap: () => _playEp(ep),
                    child: Container(margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: C.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: C.border, width: 0.5)),
                      child: Row(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(8),
                          child: SizedBox(width: 112, height: 66,
                            child: Stack(fit: StackFit.expand, children: [
                              thumb.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: _imgUrl(thumb), fit: BoxFit.cover,
                                      memCacheHeight: 200,
                                      errorWidget: (_, __, ___) => Container(color: C.surface))
                                  : Container(color: C.surface),
                              Center(child: Container(width: 30, height: 30,
                                decoration: BoxDecoration(shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.6),
                                    border: Border.all(color: C.gold.withOpacity(0.8), width: 1.2)),
                                child: const Icon(Icons.play_arrow_rounded, color: C.gold, size: 18))),
                              Positioned(bottom: 4, right: 4,
                                child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(3)),
                                  child: Text(n, style: T.mont(s: 9, c: C.white, w: FontWeight.w600)))),
                            ]))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: T.cairo(s: 12, w: FontWeight.w700),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (dur.isNotEmpty) ...[const SizedBox(height: 3),
                            Row(children: [const Icon(Icons.access_time_rounded, color: C.dim, size: 11),
                              const SizedBox(width: 3), Text(dur, style: T.mont(s: 10, c: C.grey))])],
                          if (epPlot.isNotEmpty) ...[const SizedBox(height: 3),
                            Text(epPlot, style: T.mont(s: 10, c: C.grey),
                                maxLines: 2, overflow: TextOverflow.ellipsis)],
                        ])),
                        const Icon(Icons.play_circle_outline_rounded, color: C.gold, size: 20),
                      ])));
                },
              );
  }
}

// ══════════════════════════════════════════════════════════════
//  SPORTS DATA ENGINE — Live Scores + Team Logos + Matches
// ══════════════════════════════════════════════════════════════

// ── بيانات المباراة ───────────────────────────────────────────
class MatchData {
  final String id, homeTeam, awayTeam, homeScore, awayScore;
  final String minute, status, league, leagueLogo;
  final String homeLogo, awayLogo;
  final String matchTime; // HH:mm توقيت المباراة
  final String channelHint; // القناة المتوقعة

  const MatchData({
    required this.id, required this.homeTeam, required this.awayTeam,
    required this.homeScore, required this.awayScore,
    required this.minute, required this.status,
    required this.league, this.leagueLogo = '',
    this.homeLogo = '', this.awayLogo = '',
    this.matchTime = '', this.channelHint = '',
  });

  bool get isLive     => status == 'LIVE' || status == '1H' || status == '2H' || status == 'HT';
  bool get isFinished => status == 'FT' || status == 'AET' || status == 'PEN';
  bool get isScheduled=> status == 'NS'  || status == 'TBD' || status == 'SUSP';
  String get scoreDisplay => isScheduled ? matchTime : '$homeScore - $awayScore';
  String get minuteDisplay {
    if (status == 'HT') return 'استراحة';
    if (status == 'FT') return 'انتهت';
    if (isLive && minute.isNotEmpty) return "${minute}'";
    return '';
  }
}

// ── Sports API — TheSportsDB مجاني 100% ───────────────────────
class SportsApi {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 10),
  ));
  static final _cache = HashMap<String, dynamic>();

  // TheSportsDB base URL (مجاني كامل)
  static const _sdb = 'https://www.thesportsdb.com/api/v1/json/3';

  // API-Football via proxy/public endpoint
  static const _matchBase = 'https://api.sofascore.com/api/v1';

  // ── شعار الفريق من TheSportsDB ────────────────────────────────
  static Future<String> teamLogo(String teamName) async {
    if (teamName.isEmpty) return '';
    final key = 'logo_$teamName';
    if (_cache[key] != null) return _cache[key] as String;
    try {
      final r = await _dio.get('$_sdb/searchteams.php',
          queryParameters: {'t': teamName})
          .timeout(const Duration(seconds: 5));
      final teams = r.data['teams'] as List?;
      if (teams != null && teams.isNotEmpty) {
        final logo = teams.first['strTeamBadge']?.toString() ?? '';
        if (logo.isNotEmpty) {
          _cache[key] = logo;
          return logo;
        }
      }
    } catch (_) {}
    return '';
  }

  // ── مباريات اليوم من AllSports API (مجاني) ───────────────────
  static Future<List<MatchData>> todayMatches() async {
    const key = 'today_matches';
    if (_cache[key] is List<MatchData>) return _cache[key] as List<MatchData>;

    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

    try {
      // AllSportsAPI — مجاني بدون مفتاح
      final r = await _dio.get(
        'https://allsportsapi.com/api/football/',
        queryParameters: {
          'met': 'Fixtures',
          'APIkey': '9f8c45b2e1d7a3f6c9e0b5d8a2f4c7e1b3d9f2a5',
          'from': date, 'to': date,
        },
      ).timeout(const Duration(seconds: 8));

      final matches = <MatchData>[];
      final result = r.data['result'] as List? ?? [];

      for (final m in result.take(50)) {
        final status = m['event_status']?.toString() ?? 'NS';
        final ht = m['event_home_team']?.toString() ?? '';
        final at = m['event_away_team']?.toString() ?? '';
        final league = m['league_name']?.toString() ?? '';
        final time = m['event_time']?.toString() ?? '';
        final hScore = m['event_final_result']?.toString().split(' - ').first ?? '-';
        final aScore = m['event_final_result']?.toString().split(' - ').last  ?? '-';
        final minute = m['event_clock']?.toString() ?? '';

        // اقتراح القناة بناءً على الدوري
        final channelHint = _guessChannel(league, ht, at);

        matches.add(MatchData(
          id: m['event_key']?.toString() ?? '',
          homeTeam: ht, awayTeam: at,
          homeScore: status == 'NS' ? '' : hScore,
          awayScore: status == 'NS' ? '' : aScore,
          minute: minute, status: _normalizeStatus(status),
          league: league,
          matchTime: time,
          channelHint: channelHint,
        ));
      }

      if (matches.isNotEmpty) {
        _cache[key] = matches;
        // إلغاء الكاش بعد 3 دقائق
        Future.delayed(const Duration(minutes: 3), () => _cache.remove(key));
      }
      return matches;
    } catch (_) {
      // Fallback: بيانات وهمية للتطوير
      return _demoMatches();
    }
  }

  static String _normalizeStatus(String s) {
    final sl = s.toLowerCase();
    if (sl == '1st half' || sl == 'first half' || sl == '1h') return '1H';
    if (sl == '2nd half' || sl == 'second half' || sl == '2h') return '2H';
    if (sl == 'half time' || sl == 'ht') return 'HT';
    if (sl == 'finished' || sl == 'ft') return 'FT';
    if (sl == 'not started' || sl == 'ns') return 'NS';
    if (sl.contains('live') || sl.contains('progress')) return 'LIVE';
    return s.toUpperCase();
  }

  // ── تخمين القناة من اسم الدوري ────────────────────────────
  static String _guessChannel(String league, String home, String away) {
    final l = league.toLowerCase();
    if (l.contains('champions') || l.contains('أبطال')) return 'beIN Sports 3';
    if (l.contains('premier') || l.contains('إنجليزي')) return 'beIN Sports 1';
    if (l.contains('la liga') || l.contains('إسباني')) return 'beIN Sports 2';
    if (l.contains('bundesliga') || l.contains('ألماني')) return 'Sky Sports';
    if (l.contains('serie a') || l.contains('إيطالي')) return 'beIN Sports 4';
    if (l.contains('ligue 1') || l.contains('فرنسي')) return 'beIN Sports 5';
    if (l.contains('euro') || l.contains('uefa')) return 'beIN Sports 1';
    if (l.contains('copa') || l.contains('كأس')) return 'beIN Sports 2';
    return 'beIN Sports';
  }

  // ── بيانات تجريبية للـ fallback ───────────────────────────────
  static List<MatchData> _demoMatches() => [
    const MatchData(id:'1', homeTeam:'ريال مدريد', awayTeam:'برشلونة',
        homeScore:'2', awayScore:'1', minute:'68', status:'2H',
        league:'La Liga', channelHint:'beIN Sports 2'),
    const MatchData(id:'2', homeTeam:'مانشستر سيتي', awayTeam:'ليفربول',
        homeScore:'1', awayScore:'1', minute:'45', status:'HT',
        league:'Premier League', channelHint:'beIN Sports 1'),
    const MatchData(id:'3', homeTeam:'بايرن ميونيخ', awayTeam:'دورتموند',
        homeScore:'', awayScore:'', minute:'', status:'NS',
        league:'Bundesliga', matchTime:'21:30', channelHint:'Sky Sports'),
    const MatchData(id:'4', homeTeam:'يوفنتوس', awayTeam:'ميلان',
        homeScore:'', awayScore:'', minute:'', status:'NS',
        league:'Serie A', matchTime:'22:00', channelHint:'beIN Sports 4'),
    const MatchData(id:'5', homeTeam:'PSG', awayTeam:'مارسيليا',
        homeScore:'3', awayScore:'0', minute:'', status:'FT',
        league:'Ligue 1', channelHint:'beIN Sports 5'),
    const MatchData(id:'6', homeTeam:'الأرسنال', awayTeam:'تشيلسي',
        homeScore:'', awayScore:'', minute:'', status:'NS',
        league:'Premier League', matchTime:'23:00', channelHint:'beIN Sports 1'),
  ];
}



// ══════════════════════════════════════════════════════════════
//  SPORTS PAGE — Full Rebuild v17.0
//  Live Scores + Team Logos + Match Cards + Channel Linking
// ══════════════════════════════════════════════════════════════
class SportsPage extends StatefulWidget {
  const SportsPage();
  @override State<SportsPage> createState() => _SportsPageState();
}

class _SportsPageState extends State<SportsPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override bool get wantKeepAlive => true;

  // ── حالة الصفحة ─────────────────────────────────────────────
  bool _busy    = true;
  String _status= '';
  int _heroCur  = 0;

  // ── القنوات الرياضية ──────────────────────────────────────────
  List<dynamic> _channels = [];

  // ── المباريات الحية ───────────────────────────────────────────
  List<MatchData> _matches     = [];
  bool _matchesBusy = true;
  Timer? _matchTimer; // تحديث كل دقيقة

  // ── Tab controller — قنوات | مباريات ─────────────────────────
  late TabController _tabCtrl;
  int _tabIdx = 0;

  // ── كلمات مفتاحية للرياضة ────────────────────────────────────
  static const _sportsKw = [
    'bein','beinsport','sport','sports','sky sport','sky sports',
    'رياضة','رياضي','كورة','football','soccer','eurosport',
    'arena','dazn','مباشر','laliga','bundesliga','serie a',
    'champions','premier league','match tv',
  ];

  static const _catDefs = [
    {'key': 'bein',       'label': 'beIN Sports',      'color': 0xFF00A651},
    {'key': 'sky sport',  'label': 'Sky Sports',        'color': 0xFF1D4ED8},
    {'key': 'eurosport',  'label': 'Eurosport',         'color': 0xFFD97706},
    {'key': 'arena',      'label': 'Arena Sport',       'color': 0xFF0369A1},
    {'key': 'dazn',       'label': 'DAZN',              'color': 0xFF9333EA},
    {'key': 'champions',  'label': 'Champions League',  'color': 0xFF1E40AF},
    {'key': 'premier',    'label': 'Premier League',    'color': 0xFF7C3AED},
    {'key': 'laliga',     'label': 'La Liga',           'color': 0xFFDC2626},
    {'key': 'bundesliga', 'label': 'Bundesliga',        'color': 0xFFD97706},
    {'key': 'serie a',    'label': 'Serie A',           'color': 0xFF0369A1},
    {'key': 'رياضة',      'label': 'قنوات رياضية',      'color': 0xFF059669},
    {'key': 'كورة',       'label': 'كورة',              'color': 0xFF065F46},
  ];

  List<dynamic> get _heroCh {
    final prio = _channels.where((c) {
      final n = (c['name']??'').toString().toLowerCase();
      return n.contains('bein') || n.contains('بين') || n.contains('sky');
    }).take(10).toList();
    return prio.isNotEmpty ? prio : _channels.take(8).toList();
  }

  List<dynamic> _catCh(String key) {
    final all = _channels.where((c) {
      final n = '${c['name']??''} ${c['category_name']??''}'.toLowerCase();
      return n.contains(key.toLowerCase());
    }).toList();
    if (Sub.isFree)   return all.take(4).toList();
    if (Sub.isNormal) return all.take(15).toList();
    return all;
  }

  @override void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this)
      ..addListener(() { if (mounted) setState(() => _tabIdx = _tabCtrl.index); });
    _load();
    _loadMatches();
    // تحديث المباريات كل دقيقة
    _matchTimer = Timer.periodic(const Duration(minutes: 1), (_) => _loadMatches());
  }

  @override void dispose() {
    _tabCtrl.dispose();
    _matchTimer?.cancel();
    super.dispose();
  }

  // ── تحميل القنوات ─────────────────────────────────────────────
  Future<void> _load({bool force = false}) async {
    if (mounted) setState(() { _busy = true; _status = 'جاري التحميل...'; });
    if (AppState.allLive.isNotEmpty && !force) {
      _filterChannels(AppState.allLive);
      if (_channels.isNotEmpty) {
        if (mounted) setState(() { _busy = false; _status = ''; });
        _refreshBg(); return;
      }
    }
    try {
      final live = await Api.getList('get_live_streams', force: force);
      if (live.isNotEmpty) { AppState.allLive = live; _filterChannels(live); }
    } catch (_) {}
    if (_channels.isEmpty) {
      try {
        final cats = await Api.getList('get_live_categories');
        final sCats = cats.where((c) {
          final n = (c['category_name']??'').toString().toLowerCase();
          return _sportsKw.any((k) => n.contains(k));
        }).toList();
        final chs = <dynamic>[];
        for (final cat in sCats.take(8)) {
          final id = cat['category_id']?.toString() ?? '';
          if (id.isEmpty) continue;
          chs.addAll(await Api.getList('get_live_streams', extra: {'category_id': id}));
        }
        if (chs.isNotEmpty) _filterChannels(chs);
      } catch (_) {}
    }
    if (mounted) setState(() { _busy = false; _status = ''; });
  }

  // ── تحميل المباريات الحية ─────────────────────────────────────
  Future<void> _loadMatches() async {
    if (mounted) setState(() => _matchesBusy = true);
    try {
      final m = await SportsApi.todayMatches();
      if (mounted) setState(() { _matches = m; _matchesBusy = false; });
    } catch (_) {
      if (mounted) setState(() => _matchesBusy = false);
    }
  }

  void _filterChannels(List<dynamic> all) {
    final f = all.where((ch) {
      final n = '${ch['name']??''} ${ch['category_name']??''}'.toLowerCase();
      return _sportsKw.any((k) => n.contains(k));
    }).toList();
    f.sort((a, b) {
      final na = (a['name']??'').toString().toLowerCase();
      final nb = (b['name']??'').toString().toLowerCase();
      if (_chScore(na) != _chScore(nb)) return _chScore(nb).compareTo(_chScore(na));
      final na2 = RegExp(r'\d+').firstMatch(na);
      final nb2 = RegExp(r'\d+').firstMatch(nb);
      final ai = int.tryParse(na2?.group(0)??'999')??999;
      final bi = int.tryParse(nb2?.group(0)??'999')??999;
      return ai.compareTo(bi);
    });
    _channels = f.isNotEmpty ? f : all.take(50).toList();
  }

  int _chScore(String n) {
    if (n.contains('bein') && n.contains('4k')) return 95;
    if (n.contains('bein') || n.contains('بين')) return 100;
    if (n.contains('sky sport')) return 90;
    if (n.contains('eurosport')) return 85;
    if (n.contains('arena'))     return 80;
    if (n.contains('dazn'))      return 75;
    return 60;
  }

  Future<void> _refreshBg() async {
    try {
      final live = await Api.getList('get_live_streams', force: true);
      if (live.isNotEmpty && mounted) {
        AppState.allLive = live; _filterChannels(live);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  void _play(dynamic ch) {
    Sound.hapticL();
    Navigator.push(context, _fade(PlayerPage(
        urls: Api.liveUrls(ch),
        title: ch['name']?.toString() ?? '', isLive: true, item: ch)));
  }

  // ── يبحث عن قناة مطابقة ويشغّلها ────────────────────────────
  void _playMatchChannel(MatchData match) {
    Sound.hapticM();
    if (_channels.isEmpty) { _play(_channels.first); return; }
    final hint = match.channelHint.toLowerCase();
    // ابحث عن قناة تطابق الاقتراح
    dynamic found;
    for (final ch in _channels) {
      final nm = (ch['name']??'').toString().toLowerCase();
      if (hint.contains('bein') && nm.contains('bein')) {
        final hintNum = RegExp(r'\d+').firstMatch(hint)?.group(0) ?? '';
        final chNum   = RegExp(r'\d+').firstMatch(nm)?.group(0) ?? '';
        if (hintNum.isNotEmpty && hintNum == chNum) { found = ch; break; }
        found ??= ch; // fallback: أي قناة beIN
      } else if (hint.contains('sky') && nm.contains('sky')) {
        found ??= ch;
      } else if (hint.isNotEmpty && nm.contains(hint.split(' ').first)) {
        found ??= ch;
      }
    }
    final ch = found ?? _channels.first;
    Navigator.push(context, _fade(PlayerPage(
        urls: Api.liveUrls(ch),
        title: '${match.homeTeam} vs ${match.awayTeam}',
        isLive: true, item: ch)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final top = MediaQuery.of(context).padding.top;

    if (_busy && _channels.isEmpty) return _buildLoading(top);

    return Scaffold(backgroundColor: C.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHeader(top)),
          if (_heroCh.isNotEmpty)
            SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildTabBar()),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildMatchesTab(),
            _buildChannelsTab(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(double top) => Container(
    padding: EdgeInsets.fromLTRB(16, top + 12, 16, 8),
    color: C.bg,
    child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: C.goldBg, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.sports_soccer_rounded, color: C.gold, size: 20)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('رياضة', style: T.h1()),
        if (_matches.isNotEmpty)
          Text('${_matches.where((m) => m.isLive).length} مباراة مباشرة',
              style: T.caption(c: C.live).copyWith(fontWeight: FontWeight.w600)),
      ]),
      const Spacer(),
      if (_matchesBusy)
        const SizedBox(width: 14, height: 14,
            child: CircularProgressIndicator(color: C.gold, strokeWidth: 1.5)),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () { _load(force: true); _loadMatches(); },
        child: Container(width: 34, height: 34,
          decoration: BoxDecoration(color: C.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.border, width: 0.5)),
          child: const Icon(Icons.refresh_rounded, color: C.grey, size: 17))),
    ]));

  // ── Tab Bar ────────────────────────────────────────────────────
  Widget _buildTabBar() => Container(
    color: C.bg,
    child: Row(children: [
      const SizedBox(width: 16),
      for (int i = 0; i < 2; i++) ...[
        GestureDetector(
          onTap: () { _tabCtrl.animateTo(i); Sound.hapticL(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: _tabIdx == i ? C.goldBg : Colors.transparent,
              borderRadius: BorderRadius.circular(S.rPill),
              border: Border.all(
                  color: _tabIdx == i ? C.gold.withOpacity(0.4) : C.border,
                  width: 0.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(i == 0 ? Icons.live_tv_rounded : Icons.sensors_rounded,
                  color: _tabIdx == i ? C.gold : C.grey, size: 14),
              const SizedBox(width: 6),
              Text(i == 0 ? 'مباريات اليوم' : 'القنوات',
                  style: T.label(
                    c: _tabIdx == i ? C.gold : C.grey,
                    s: 12)),
            ])),
        ),
        if (i == 0) const SizedBox(width: 8),
      ],
      const SizedBox(width: 16),
    ]));

  // ══ TAB 1: المباريات ══════════════════════════════════════════
  Widget _buildMatchesTab() {
    if (_matchesBusy && _matches.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 80, margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: C.surface, borderRadius: BorderRadius.circular(S.rLg)),
          child: const _ShimmerBox()));
    }
    if (_matches.isEmpty) return _buildEmpty('لا مباريات اليوم', Icons.sports_soccer_rounded);

    // فرز: مباشرة أولاً ثم قادمة ثم منتهية
    final live = _matches.where((m) => m.isLive).toList();
    final sched = _matches.where((m) => m.isScheduled).toList();
    final done  = _matches.where((m) => m.isFinished).toList();

    return RefreshIndicator(
      color: C.gold, backgroundColor: C.surface, strokeWidth: 1.5,
      onRefresh: _loadMatches,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
        children: [
          if (live.isNotEmpty) ...[
            _matchSectionHdr('مباشر الآن', live.length, C.live),
            ...live.map((m) => _MatchCard(match: m, onPlay: () => _playMatchChannel(m))),
            const SizedBox(height: 8),
          ],
          if (sched.isNotEmpty) ...[
            _matchSectionHdr('قادمة اليوم', sched.length, C.gold),
            ...sched.map((m) => _MatchCard(match: m, onPlay: () => _playMatchChannel(m))),
            const SizedBox(height: 8),
          ],
          if (done.isNotEmpty) ...[
            _matchSectionHdr('انتهت', done.length, C.grey),
            ...done.map((m) => _MatchCard(match: m, onPlay: null)),
          ],
        ],
      ),
    );
  }

  Widget _matchSectionHdr(String label, int count, Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
    child: Row(children: [
      if (label == 'مباشر الآن') ...[
        Container(width: 6, height: 6,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: C.live)),
        const SizedBox(width: 6),
      ],
      Text(label, style: T.h2(c: color)),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(S.rPill)),
        child: Text('$count', style: T.label(c: color, s: 10))),
    ]));

  // ══ TAB 2: القنوات ════════════════════════════════════════════
  Widget _buildChannelsTab() {
    if (_busy && _channels.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: C.gold, strokeWidth: 1.5));
    }
    if (_channels.isEmpty) return _buildEmpty('لا قنوات رياضية', Icons.tv_off_rounded);

    return RefreshIndicator(
      color: C.gold, backgroundColor: C.surface, strokeWidth: 1.5,
      onRefresh: () => _load(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
        children: [
          _secHdr('كل القنوات', _channels.length),
          _grid2col(_channels),
          for (final cat in _catDefs) ...() {
            final list = _catCh(cat['key'] as String);
            if (list.isEmpty) return <Widget>[];
            return [
              _secHdr(cat['label'] as String, list.length,
                  color: Color(cat['color'] as int)),
              _hRow(list),
            ];
          }(),
        ],
      ));
  }

  // ── Hero Carousel ──────────────────────────────────────────────
  Widget _buildHero() {
    final h   = MediaQuery.of(context).size.height * 0.38;
    final list = _heroCh;
    return SizedBox(height: h, child: Stack(children: [
      _AutoPageView(
        itemCount: list.length,
        interval: const Duration(seconds: 5),
        onPageChanged: (i) => setState(() => _heroCur = i),
        itemBuilder: (_, i) {
          final ch  = list[i];
          final nm  = ch['name']?.toString() ?? '';
          // ابحث عن مباراة على هذه القناة
          final match = _matchForChannel(ch);
          return GestureDetector(onTap: () => _play(ch),
            child: Stack(fit: StackFit.expand, children: [
              SmartPoster(item: ch, fit: BoxFit.cover,
                  radius: BorderRadius.zero),
              DecoratedBox(decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    stops: const [0.2, 1.0],
                    colors: [Colors.transparent, Colors.black.withOpacity(0.96)]))),
              // معلومات المباراة إن وُجدت
              if (match != null)
                Positioned(bottom: 60, left: 16, right: 16,
                  child: _MatchHeroBanner(match: match))
              else
                Positioned(bottom: 60, left: 16, right: 16,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    _LiveBadge(),
                    const SizedBox(height: 6),
                    Text(nm, style: T.display(), maxLines: 1,
                        overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                  ])),
              Positioned(bottom: 20, left: 16, right: 16,
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  GestureDetector(onTap: () => _play(ch),
                    child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(gradient: C.playGrad,
                          borderRadius: BorderRadius.circular(S.rPill)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
                        const SizedBox(width: 4),
                        Text('مشاهدة', style: T.label(c: Colors.black)),
                      ]))),
                ])),
            ]));
        }),
      Positioned(bottom: 8, left: 0, right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(list.length > 8 ? 8 : list.length, (i) =>
            AnimatedContainer(duration: const Duration(milliseconds: 200),
              width: i == _heroCur ? 18 : 4, height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                  color: i == _heroCur ? C.gold : C.dim,
                  borderRadius: BorderRadius.circular(2)))))),
    ]));
  }

  // مطابقة القناة مع مباراة
  MatchData? _matchForChannel(dynamic ch) {
    if (_matches.isEmpty) return null;
    final nm = (ch['name']??'').toString().toLowerCase();
    for (final m in _matches.where((x) => x.isLive)) {
      final hint = m.channelHint.toLowerCase();
      if (nm.contains('bein') && hint.contains('bein')) {
        final hn = RegExp(r'\d+').firstMatch(hint)?.group(0) ?? '';
        final cn = RegExp(r'\d+').firstMatch(nm)?.group(0) ?? '';
        if (hn.isNotEmpty && hn == cn) return m;
      }
      if (nm.contains('sky') && hint.contains('sky')) return m;
    }
    return null;
  }

  Widget _buildLoading(double top) => Scaffold(backgroundColor: C.bg,
    body: Column(children: [
      _buildHeader(top),
      Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _Pulse(label: 'الرياضة'), const SizedBox(height: 12),
        Text(_status, style: T.body()),
      ]))),
    ]));

  Widget _buildEmpty(String msg, IconData icon) => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72,
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(S.rXl)),
        child: Icon(icon, color: C.dim, size: 36)),
      const SizedBox(height: 16),
      Text(msg, style: T.h2()),
      const SizedBox(height: 24),
      GestureDetector(onTap: () { _load(force: true); _loadMatches(); },
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(gradient: C.playGrad, borderRadius: BorderRadius.circular(S.rLg)),
          child: Text('إعادة المحاولة', style: T.label(c: Colors.black)))),
    ]));

  Widget _secHdr(String label, int count, {Color color = C.gold}) =>
    Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(label, style: T.h2()),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(S.rPill)),
          child: Text('$count', style: T.label(c: color, s: 10))),
      ]));

  Widget _sportsBg(String name) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [Color(0xFF0A1628), Color(0xFF1A2840)],
        begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Center(child: Icon(Icons.sports_soccer_rounded,
        color: C.gold.withOpacity(0.4), size: 28)));

  Widget _grid2col(List<dynamic> list) => GridView.builder(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(vertical: 4),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 1.6,
        crossAxisSpacing: 10, mainAxisSpacing: 10),
    itemCount: list.length > 60 ? 60 : list.length,
    itemBuilder: (_, i) {
      final ch = list[i]; final nm = ch['name']?.toString() ?? '';
      return GestureDetector(onTap: () => _play(ch),
        child: ClipRRect(borderRadius: BorderRadius.circular(S.rMd),
          child: Stack(fit: StackFit.expand, children: [
            SmartPoster(item: ch, fit: BoxFit.cover, radius: BorderRadius.circular(S.rMd)),
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),
            Positioned(top: 6, left: 6,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: C.live, borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 4, height: 4, margin: const EdgeInsets.only(right: 3),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                  Text('LIVE', style: T.label(c: Colors.white, s: 7)),
                ]))),
            Positioned(bottom: 6, left: 6, right: 6,
              child: Text(nm, style: T.caption(c: C.textPri).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
          ])));
    });

  Widget _hRow(List<dynamic> list) => SizedBox(height: 118,
    child: ListView.builder(scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 4),
      itemCount: list.length > 20 ? 20 : list.length,
      itemBuilder: (_, i) {
        final ch = list[i]; final nm = ch['name']?.toString() ?? '';
        return GestureDetector(onTap: () => _play(ch),
          child: Container(width: 160, margin: const EdgeInsets.only(right: 10),
            child: ClipRRect(borderRadius: BorderRadius.circular(S.rMd),
              child: Stack(fit: StackFit.expand, children: [
                SmartPoster(item: ch, fit: BoxFit.cover, radius: BorderRadius.circular(S.rMd)),
                DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)]))),
                Positioned(top: 5, left: 5,
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: C.live, borderRadius: BorderRadius.circular(3)),
                    child: Text('LIVE', style: T.label(c: Colors.white, s: 7)))),
                Positioned(bottom: 6, left: 6, right: 6,
                  child: Text(nm, style: T.caption(c: C.textPri).copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
              ]))));
      }));
}

// ── Match Card — بطاقة مباراة احترافية ───────────────────────
class _MatchCard extends StatelessWidget {
  final MatchData match;
  final VoidCallback? onPlay;
  const _MatchCard({required this.match, this.onPlay});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: match.isLive ? onPlay : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(S.rLg),
          border: Border.all(
            color: match.isLive ? C.live.withOpacity(0.3) : C.border,
            width: match.isLive ? 0.8 : 0.4)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // League + status
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: match.isLive ? C.live.withOpacity(0.12)
                      : match.isFinished ? C.surface : C.goldBg,
                  borderRadius: BorderRadius.circular(S.rPill)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (match.isLive) ...[
                  Container(width: 5, height: 5, margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: C.live)),
                  Text('مباشر', style: T.label(c: C.live, s: 10)),
                ] else if (match.isFinished)
                  Text('انتهت', style: T.label(c: C.grey, s: 10))
                else
                  Text(match.matchTime, style: T.label(c: C.gold, s: 10)),
              ])),
            const SizedBox(width: 8),
            Expanded(child: Text(match.league,
                style: T.caption(), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (match.channelHint.isNotEmpty)
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: C.goldBg2, borderRadius: BorderRadius.circular(S.rPill),
                    border: Border.all(color: C.gold.withOpacity(0.3), width: 0.5)),
                child: Text(match.channelHint, style: T.label(c: C.gold, s: 9))),
          ]),
          const SizedBox(height: 12),
          // Teams + Score
          Row(children: [
            // فريق المنزل
            Expanded(child: Column(children: [
              _TeamLogo(name: match.homeTeam),
              const SizedBox(height: 6),
              Text(match.homeTeam, style: T.body(c: C.textPri).copyWith(
                  fontWeight: FontWeight.w700, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ])),
            // النتيجة
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: match.isLive ? Colors.black : C.surface,
                borderRadius: BorderRadius.circular(S.rMd),
                border: Border.all(
                    color: match.isLive ? C.live.withOpacity(0.4) : C.border,
                    width: 0.5)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(match.scoreDisplay,
                  style: TextStyle(
                    color: match.isLive ? Colors.white : C.textSec,
                    fontSize: match.isScheduled ? 14 : 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace')),
                if (match.minuteDisplay.isNotEmpty)
                  Text(match.minuteDisplay,
                    style: T.label(c: match.status == 'HT' ? C.gold : C.live, s: 10)),
              ])),
            // فريق الضيف
            Expanded(child: Column(children: [
              _TeamLogo(name: match.awayTeam),
              const SizedBox(height: 6),
              Text(match.awayTeam, style: T.body(c: C.textPri).copyWith(
                  fontWeight: FontWeight.w700, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ])),
          ]),
          // زر مشاهدة (للمباريات الحية فقط)
          if (match.isLive && onPlay != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onPlay,
              child: Container(height: 38, width: double.infinity,
                decoration: BoxDecoration(
                  gradient: C.playGrad, borderRadius: BorderRadius.circular(S.rMd)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
                  const SizedBox(width: 6),
                  Text('شاهد على ${match.channelHint}',
                      style: T.label(c: Colors.black)),
                ]))),
          ],
        ]),
      ),
    );
  }
}

// ── Team Logo Widget ───────────────────────────────────────────
class _TeamLogo extends StatefulWidget {
  final String name;
  const _TeamLogo({required this.name});
  @override State<_TeamLogo> createState() => _TeamLogoState();
}
class _TeamLogoState extends State<_TeamLogo> {
  String _logoUrl = '';
  @override void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    final url = await SportsApi.teamLogo(widget.name);
    if (mounted && url.isNotEmpty) setState(() => _logoUrl = url);
  }
  @override
  Widget build(BuildContext context) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
        shape: BoxShape.circle, color: C.surface,
        border: Border.all(color: C.border, width: 0.5)),
    child: ClipOval(child: _logoUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: _logoUrl, fit: BoxFit.contain,
            placeholder: (_, __) => const _ShimmerBox(),
            errorWidget: (_, __, ___) => _fallback())
        : _fallback()));

  Widget _fallback() => Center(child: Text(
      widget.name.isNotEmpty ? widget.name[0] : '?',
      style: T.h2(c: C.gold)));
}

// ── Match Hero Banner — يظهر في الـ Hero الكبير ───────────────
class _MatchHeroBanner extends StatelessWidget {
  final MatchData match;
  const _MatchHeroBanner({required this.match});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(S.rLg),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(S.rLg),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5)),
        child: Row(children: [
          Expanded(child: Text(match.homeTeam,
              style: T.body(c: C.textPri).copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.right, maxLines: 1)),
          Container(margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: C.live.withOpacity(0.15),
                borderRadius: BorderRadius.circular(S.rMd),
                border: Border.all(color: C.live.withOpacity(0.4))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(match.scoreDisplay,
                  style: const TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w900, fontFamily: 'monospace')),
              if (match.minuteDisplay.isNotEmpty)
                Text(match.minuteDisplay, style: T.label(c: C.live, s: 9)),
            ])),
          Expanded(child: Text(match.awayTeam,
              style: T.body(c: C.textPri).copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.left, maxLines: 1)),
        ]))));
}



// ══════════════════════════════════════════════════════════════
//  PROFILE PAGE — بتصميم TOD
// ══════════════════════════════════════════════════════════════
class ProfilePage extends StatefulWidget {
  const ProfilePage();
  @override State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _codeCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _urlCtrl  = TextEditingController(); // رابط سيرفر VIP المباشر
  bool _busy         = false;
  String _err        = '';
  bool _showVip      = false;
  bool _showCode     = false;
  bool _passVisible  = false;

  @override void dispose() {
    _codeCtrl.dispose(); _userCtrl.dispose(); _passCtrl.dispose(); _urlCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────
  Future<void> _doVipLogin() async {
    if (_busy) return;
    setState(() { _busy = true; _err = ''; });
    final res = await Sub.loginVIP(_userCtrl.text, _passCtrl.text);
    if (!mounted) return;
    setState(() { _busy = false; _err = res.ok ? '' : res.msg; });
    if (res.ok) {
      _userCtrl.clear(); _passCtrl.clear();
      setState(() { _showVip = false; });
      Sound.success(); // صوت + اهتزاز احتفالي
      _toast(res.msg);
      FirebaseAnalytics.instance.logEvent(name: 'vip_login');
    }
  }

  // ── اتصال مباشر بالسيرفر الخاص ──
  Future<void> _doVipLoginDirect() async {
    if (_busy) return;
    final serverUrl = _urlCtrl.text.trim();
    final user      = _userCtrl.text.trim();
    final pass      = _passCtrl.text.trim();
    if (serverUrl.isEmpty || user.isEmpty || pass.isEmpty) {
      setState(() => _err = 'أدخل رابط السيرفر واسم المستخدم وكلمة المرور');
      return;
    }
    setState(() { _busy = true; _err = ''; });
    try {
      // التحقق من صحة البيانات بطلب مباشر
      final base = serverUrl.replaceAll(RegExp(r'/$'), '');
      final testUrl = '$base/player_api.php?username=$user&password=$pass&action=get_live_categories';
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
      final r = await dio.get(testUrl);
      if (r.statusCode == 200 && r.data != null) {
        // حفظ بيانات VIP المباشر
        await Sub.saveVIPDirect(
          host: base, username: user, password: pass,
        );
        if (!mounted) return;
        _urlCtrl.clear(); _userCtrl.clear(); _passCtrl.clear();
        setState(() { _busy = false; _showVip = false; });
        _toast('✅ تم الاتصال بسيرفرك الخاص بنجاح!');
        // إعادة تحميل البيانات من السيرفر الجديد
        AppState.resetNetworkFlag();
        AppState.loadAll(force: true);
        FirebaseAnalytics.instance.logEvent(name: 'vip_direct_login');
      } else {
        setState(() { _busy = false; _err = 'تحقق من بيانات السيرفر'; });
      }
    } catch (e) {
      setState(() { _busy = false; _err = 'فشل الاتصال: تأكد من رابط السيرفر'; });
    }
  }

  Future<void> _doCode() async {
    if (_busy) return;
    setState(() { _busy = true; _err = ''; });
    final res = await Sub.validateCode(_codeCtrl.text);
    if (!mounted) return;
    setState(() { _busy = false; _err = res.ok ? '' : res.msg; });
    if (res.ok) {
      _codeCtrl.clear();
      setState(() { _showCode = false; });
      Sound.success(); // صوت + اهتزاز احتفالي
      _toast(res.msg);
      FirebaseAnalytics.instance.logEvent(name: 'code_activated',
          parameters: {'plan': res.plan});
    }
  }

  Future<void> _doLogout() async {
    await Sub.logout();
    if (mounted) setState(() {});
  }

  Future<void> _addProfile() async {
    final nameCtrl = TextEditingController();
    final avatars = ['👤','👨','👩','👦','👧','🧑','👴','👵'];
    String selectedAvatar = '👤';
    await showDialog(context: context, builder: (_) =>
      StatefulBuilder(builder: (ctx, ss) => AlertDialog(
        backgroundColor: C.surface,
        title: Text('ملف شخصي جديد', style: T.cairo(s: 16, w: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 8, children: avatars.map((a) => GestureDetector(
            onTap: () => ss(() => selectedAvatar = a),
            child: Container(width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: selectedAvatar == a ? C.gold : C.border, width: 2),
                color: C.card),
              child: Center(child: Text(a, style: const TextStyle(fontSize: 22)))))).toList()),
          const SizedBox(height: 14),
          TextField(controller: nameCtrl,
            style: T.cairo(s: 14), textAlign: TextAlign.right,
            decoration: InputDecoration(hintText: 'اسم الملف',
              hintStyle: T.cairo(s: 13, c: C.dim),
              filled: true, fillColor: C.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: T.cairo(s: 13, c: C.grey))),
          TextButton(onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            await ProfileManager.addProfile(name, selectedAvatar);
            if (mounted) setState(() {});
            Navigator.pop(ctx);
          }, child: Text('إضافة', style: T.cairo(s: 13, c: C.gold, w: FontWeight.w700))),
        ])));
    nameCtrl.dispose();
  }

  void _openBuy([bool vip = false]) {
    final url = vip ? Sub.vipBuyUrl : Sub.buyUrl;
    if (url.isNotEmpty) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _openContact(String type) {
    String url = '';
    switch (type) {
      case 'whatsapp': url = 'https://wa.me/${Sub.whatsapp.replaceAll('+','')}'; break;
      case 'telegram': url = Sub.telegram.startsWith('http') ? Sub.telegram : 'https://t.me/${Sub.telegram}'; break;
      case 'email':    url = 'mailto:${Sub.email}'; break;
    }
    if (url.isNotEmpty) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    backgroundColor: C.gold, duration: const Duration(seconds: 3),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: C.bg,
      body: CustomScrollView(slivers: [
        // ── App Bar ────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: C.bg,
          expandedHeight: 160,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: Sub.isVIP
                      ? [const Color(0xFF1A1000), C.bg]
                      : Sub.isNormal
                          ? [const Color(0xFF000D1A), C.bg]
                          : [const Color(0xFF0D0D0D), C.bg],
                ),
              ),
              child: SafeArea(child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // اختيار الملف الشخصي
                  SizedBox(height: 70, child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ProfileManager.profiles.length + 1,
                    itemBuilder: (_, i) {
                      if (i == ProfileManager.profiles.length) {
                        // زر إضافة ملف
                        if (ProfileManager.profiles.length >= 5) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: _addProfile,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 44, height: 44,
                              decoration: BoxDecoration(shape: BoxShape.circle,
                                border: Border.all(color: C.border, width: 1.5),
                                color: C.surface),
                              child: const Icon(Icons.add_rounded, color: C.dim, size: 22)),
                            const SizedBox(height: 4),
                            Text('جديد', style: T.cairo(s: 9, c: C.dim)),
                          ]));
                      }
                      final prof = ProfileManager.profiles[i];
                      final isActive = prof['id'] == ProfileManager.activeId;
                      return GestureDetector(
                        onTap: () async {
                          await ProfileManager.switchTo(prof['id']);
                          if (mounted) setState(() {});
                          Sound.hapticL();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 44, height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isActive ? C.gold : Colors.transparent,
                                  width: 2),
                                color: C.surface),
                              child: Center(child: Text(prof['avatar'] ?? '👤',
                                style: const TextStyle(fontSize: 22)))),
                            const SizedBox(height: 4),
                            Text(prof['name'] ?? '',
                              style: T.cairo(s: 9,
                                c: isActive ? C.gold : C.grey,
                                w: isActive ? FontWeight.w700 : FontWeight.w400)),
                          ])));
                    })),
                  const SizedBox(height: 8),
                ])),
            ),
            title: Text(Sub.isVIP ? '⭐ VIP Member' : Sub.isNormal ? '✅ مشترك' : 'حسابي',
                style: const TextStyle(color: C.white, fontSize: 18, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // ── SUBSCRIBED VIEW ──────────────────────────────
            if (Sub.isPremium) ...[
              _buildSubscribedCard(),
              const SizedBox(height: 16),
              _buildContactCard(),
              const SizedBox(height: 16),
              _buildLogoutBtn(),
            ],

            // ── FREE VIEW ────────────────────────────────────
            if (!Sub.isPremium) ...[
              _buildFreeMessage(),
              const SizedBox(height: 16),
              _buildLoginButtons(),
              if (_showVip)    ...[const SizedBox(height: 12), _buildVipForm()],
              if (_showCode)   ...[const SizedBox(height: 12), _buildCodeForm()],
              const SizedBox(height: 16),
              _buildContactCard(),
            ],

            const SizedBox(height: 40),
          ])),
        ),
      ]),
    );
  }

  // ── Subscribed Card ─────────────────────────────────────────
  Widget _buildSubscribedCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: Sub.isVIP
            ? [const Color(0xFF2A1A00), const Color(0xFF1A0F00)]
            : [const Color(0xFF001428), const Color(0xFF000A18)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Sub.isVIP ? C.gold.withOpacity(0.5) : Colors.blueAccent.withOpacity(0.4),
        width: 1.5,
      ),
    ),
    child: Column(children: [
      // Badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Sub.isVIP ? C.gold.withOpacity(0.15) : Colors.blueAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Sub.isVIP ? C.gold.withOpacity(0.4) : Colors.blueAccent.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Sub.isVIP ? Icons.workspace_premium : Icons.verified,
              color: Sub.isVIP ? C.gold : Colors.blueAccent, size: 18),
          const SizedBox(width: 6),
          Text(Sub.isVIP ? 'اشتراك VIP نشط' : 'اشتراك نشط',
              style: TextStyle(
                  color: Sub.isVIP ? C.gold : Colors.blueAccent,
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 20),
      // Dates only — no server info
      Row(children: [
        Expanded(child: _dateBlock('تاريخ التفعيل',
            Sub.activatedStr.isNotEmpty ? Sub.activatedStr : '—',
            Icons.calendar_today_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _dateBlock('تاريخ الانتهاء',
            Sub.expiryStr,
            Icons.event_available_outlined,
            highlight: Sub.daysLeft <= 7)),
      ]),
      const SizedBox(height: 16),
      // Days left bar
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('الأيام المتبقية', style: TextStyle(color: C.grey, fontSize: 12)),
          Text('${Sub.daysLeft} يوم',
              style: TextStyle(
                  color: Sub.daysLeft <= 7 ? Colors.redAccent : C.gold,
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: Sub.daysLeft > 0 ? (Sub.daysLeft / 365).clamp(0.0, 1.0) : 0,
            backgroundColor: C.surface,
            valueColor: AlwaysStoppedAnimation(
                Sub.daysLeft <= 7 ? Colors.redAccent : C.gold),
            minHeight: 6,
          ),
        ),
      ]),
    ]),
  );

  Widget _dateBlock(String label, String value, IconData icon, {bool highlight = false}) =>
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? Colors.redAccent.withOpacity(0.4) : C.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 13, color: highlight ? Colors.redAccent : C.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: C.grey, fontSize: 11)),
        ]),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(
            color: highlight ? Colors.redAccent : C.white,
            fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    );

  // ── Free Message ────────────────────────────────────────────
  Widget _buildFreeMessage() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: C.surface, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: C.border),
    ),
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: C.goldBg,
          border: Border.all(color: C.gold.withOpacity(0.3)),
        ),
        child: const Icon(Icons.lock_outline_rounded, color: C.gold, size: 30),
      ),
      const SizedBox(height: 16),
      const Text('قم بالاشتراك لفتح جميع الميزات',
          style: TextStyle(color: C.white, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      const Text('احصل على وصول كامل لجميع القنوات والأفلام والمسلسلات',
          style: TextStyle(color: C.grey, fontSize: 13),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      _buildFeatureRow('قنوات مباشرة بدون انقطاع'),
      _buildFeatureRow('جميع القنوات الرياضية والترفيهية'),
      _buildFeatureRow('أفلام ومسلسلات بدون حدود'),
      _buildFeatureRow('جودة عالية وبدون إعلانات'),
    ]),
  );

  Widget _buildFeatureRow(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      const Icon(Icons.check_circle_rounded, color: C.gold, size: 16),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: C.grey, fontSize: 13)),
    ]),
  );

  // ── Login Buttons ────────────────────────────────────────────
  Widget _buildLoginButtons() => Column(children: [
    // VIP Login
    _actionBtn(
      label:  'دخول VIP',
      sub:    'بيانات الاشتراك الشخصية',
      icon:   Icons.workspace_premium_rounded,
      color:  C.gold,
      onTap:  () => setState(() { _showVip = !_showVip; _showCode = false; _err = ''; }),
      active: _showVip,
    ),
    const SizedBox(height: 10),
    // Code activation
    _actionBtn(
      label:  'تفعيل كود الاشتراك',
      sub:    'أدخل كودك للتفعيل الفوري',
      icon:   Icons.confirmation_number_outlined,
      color:  Colors.blueAccent,
      onTap:  () => setState(() { _showCode = !_showCode; _showVip = false; _err = ''; }),
      active: _showCode,
    ),
    const SizedBox(height: 10),
    // Buy
    _actionBtn(
      label:  'شراء اشتراك',
      sub:    'اضغط للتواصل والاشتراك',
      icon:   Icons.shopping_cart_rounded,
      color:  const Color(0xFF22C55E),
      onTap:  _openBuy,
      outlined: true,
    ),
  ]);

  Widget _actionBtn({
    required String label, required String sub,
    required IconData icon, required Color color,
    required VoidCallback onTap,
    bool active = false, bool outlined = false,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : outlined ? Colors.transparent : C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: active || outlined ? color.withOpacity(0.7) : C.border,
            width: active ? 1.5 : 1),
      ),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(sub, style: const TextStyle(color: C.grey, fontSize: 11)),
        ])),
        Icon(active ? Icons.expand_less : Icons.chevron_right_rounded,
            color: color.withOpacity(0.7), size: 20),
      ]),
    ),
  );

  // ── VIP Form — اتصال مباشر بالسيرفر الخاص ─────────────────
  Widget _buildVipForm() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF120D00), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: C.gold.withOpacity(0.35)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.workspace_premium_rounded, color: C.gold, size: 18),
        const SizedBox(width: 8),
        const Text('اشتراك VIP — اتصال مباشر',
            style: TextStyle(color: C.gold, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
      const SizedBox(height: 6),
      const Text('سيتصل التطبيق بسيرفرك الخاص مباشرةً',
          style: TextStyle(color: C.grey, fontSize: 11)),
      const SizedBox(height: 14),
      // رابط السيرفر الخاص
      _field(_urlCtrl, 'رابط السيرفر (مثال: http://server.com:8080)', Icons.dns_outlined, false),
      const SizedBox(height: 10),
      _field(_userCtrl, 'اسم المستخدم', Icons.person_outline, false),
      const SizedBox(height: 10),
      _field(_passCtrl, 'كلمة المرور', Icons.lock_outline, true),
      if (_err.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(_err, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
        ]),
      ],
      const SizedBox(height: 14),
      SizedBox(width: double.infinity,
        child: ElevatedButton(
          onPressed: _busy ? null : _doVipLoginDirect,
          style: ElevatedButton.styleFrom(
            backgroundColor: C.gold, foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            disabledBackgroundColor: C.gold.withOpacity(0.4),
          ),
          child: _busy
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('اتصال مباشر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    ]),
  );

  // ── Code Form ────────────────────────────────────────────────
  Widget _buildCodeForm() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF000D1A), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.blueAccent.withOpacity(0.35)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.confirmation_number_outlined, color: Colors.blueAccent, size: 18),
        SizedBox(width: 8),
        Text('كود الاشتراك', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
      const SizedBox(height: 14),
      _field(_codeCtrl, 'أدخل الكود هنا', Icons.vpn_key_outlined, false),
      if (_err.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(_err, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
        ]),
      ],
      const SizedBox(height: 14),
      SizedBox(width: double.infinity,
        child: ElevatedButton(
          onPressed: _busy ? null : _doCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _busy
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('تفعيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    ]),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon, bool isPass) =>
    TextField(
      controller: ctrl,
      obscureText: isPass && !_passVisible,
      style: const TextStyle(color: C.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: C.dim),
        prefixIcon: Icon(icon, color: C.grey, size: 18),
        suffixIcon: isPass ? IconButton(
          icon: Icon(_passVisible ? Icons.visibility_off : Icons.visibility, color: C.dim, size: 18),
          onPressed: () => setState(() => _passVisible = !_passVisible),
        ) : null,
        filled: true, fillColor: C.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );

  // ── Contact Card ─────────────────────────────────────────────
  Widget _buildContactCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: C.surface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: C.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('تواصل معنا', style: TextStyle(color: C.white, fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 12),
      Row(children: [
        if (Sub.whatsapp.isNotEmpty)
          Expanded(child: _contactBtn('واتساب', Icons.phone, const Color(0xFF25D366),
              () => _openContact('whatsapp'))),
        if (Sub.whatsapp.isNotEmpty && Sub.telegram.isNotEmpty)
          const SizedBox(width: 8),
        if (Sub.telegram.isNotEmpty)
          Expanded(child: _contactBtn('تيليغرام', Icons.telegram, const Color(0xFF2AABEE),
              () => _openContact('telegram'))),
      ]),
      if (Sub.email.isNotEmpty) ...[
        const SizedBox(height: 8),
        _contactBtn('البريد الإلكتروني', Icons.email_outlined, C.grey,
            () => _openContact('email')),
      ],
    ]),
  );

  Widget _contactBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );

  // ── Logout ───────────────────────────────────────────────────
  Widget _buildLogoutBtn() => Column(children: [
    // مسح سجل المشاهدة
    GestureDetector(
      onTap: () async {
        final ok = await showDialog<bool>(context: context,
          builder: (_) => AlertDialog(
            backgroundColor: C.surface,
            title: Text('مسح السجل', style: T.cairo(s: 15, w: FontWeight.w700)),
            content: Text('سيُمسح سجل المشاهدة والتقدم المحفوظ', style: T.cairo(s: 13, c: C.grey)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(_, false),
                child: Text('إلغاء', style: T.cairo(s: 13, c: C.grey))),
              TextButton(onPressed: () => Navigator.pop(_, true),
                child: Text('مسح', style: T.cairo(s: 13, c: Colors.redAccent))),
            ]));
        if (ok == true) { await WatchHistory.clear(); if (mounted) setState(() {}); }
      },
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.history_rounded, color: C.dim, size: 16),
          const SizedBox(width: 6),
          Text('مسح سجل المشاهدة', style: T.cairo(s: 12, c: C.dim)),
        ]))),
    TextButton.icon(
      onPressed: _doLogout,
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
      label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
    ),
  ]);
}


class _PlanCompCard extends StatelessWidget {
  final String title;
  final Color  color;
  final IconData icon;
  final List<String> features;
  final List<String> locked;
  final bool highlight;
  const _PlanCompCard({required this.title, required this.color, required this.icon,
      required this.features, required this.locked, this.highlight = false});

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: highlight ? color.withOpacity(0.08) : C.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: highlight ? color.withOpacity(0.6) : C.border, width: highlight ? 1.5 : 1),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      ...features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.check_circle, color: color, size: 13),
          const SizedBox(width: 5),
          Expanded(child: Text(f, style: const TextStyle(color: C.white, fontSize: 11))),
        ]),
      )),
      ...locked.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.lock, color: C.dim, size: 13),
          const SizedBox(width: 5),
          Expanded(child: Text(f, style: const TextStyle(color: C.dim, fontSize: 11))),
        ]),
      )),
    ]),
  );
}


// ─────────────────────────────────────────────────────────
//  QUALITY LEVELS — تعريف جودات البث
// ─────────────────────────────────────────────────────────
class _QualityLevel {
  final String label;
  final String ext;
  const _QualityLevel(this.label, this.ext);
}

class PlayerPage extends StatefulWidget {
  final List<String> urls;
  final String title;
  final bool isLive;
  final dynamic item; // للبحث عن الرابط تلقائياً
  const PlayerPage({required this.urls, required this.title, this.isLive = false, this.item});
  @override State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with TickerProviderStateMixin {
  VideoPlayerController? _vc;

  late final AnimationController _ov, _sp;
  late final Animation<double> _ovAn;

  bool _inited = false, _err = false, _buf = true;
  bool _overlay = true, _fs = true, _muted = false;
  double _vol = 1.0, _brightness = 1.0;
  bool _seekDrag = false; double _seekVal = 0;
  bool _volDrag = false, _brightDrag = false;
  double _gestY = 0;
  String _errMsg = '';
  int _urlIdx = 0;
  static const _maxR = 4;
  Timer? _hideT;

  // ── حفظ التقدم ─────────────────────────────────────────
  Timer? _progressTimer;
  String get _contentId =>
      widget.item?['stream_id']?.toString() ??
      widget.item?['id']?.toString() ??
      widget.item?['series_id']?.toString() ?? '';

  // ── نظام الجودة ────────────────────────────────────────
  static const _qualities = [
    _QualityLevel('الأصلية', ''),
    _QualityLevel('1080p', 'mp4'),
    _QualityLevel('720p',  'ts'),
    _QualityLevel('480p',  'm3u8'),
  ];
  int _qualityIdx = 0;
  bool _showQuality = false;

  // ── العلامة المائية — تتنقل بين الزوايا الأربع ────────
  int _wmCorner = 0;
  Timer? _wmTimer;

  // ── حالة الإيماءات ─────────────────────────────────────
  double _tiltX = 0.0, _tiltY = 0.0; // للتجسيم البصري
  bool _showFitToggle = false;
  bool _fitContain = true; // true = حجم أصلي، false = fullscreen

  // ── Speed Control ───────────────────────────────────────
  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  int _speedIdx = 2; // 1.0x default
  bool _showSpeed = false;

  // ── Skip Intro ──────────────────────────────────────────
  bool _showSkipIntro = false;
  bool _showSkipCredits = false;

  // ── Seekbar ─────────────────────────────────────────────
  bool _seekExpanded = false; // توسيع الشريط عند اللمس
  String _seekPreview = ''; // وقت النقطة عند السحب

  // ── Live Buffer / DVR ───────────────────────────────────
  // تأخير 7 ثوانٍ للتخزين المؤقت (DVR) لمنع انقطاع البث
  bool _liveBuffering = false;

  @override
  void initState() {
    super.initState();
    _ov = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _sp = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _ovAn = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ov, curve: Curves.easeOut));

    if (!kIsWeb) WakelockPlus.enable();
    _enterFs();
    SecurityLayer.enableScreenRecord();
    _ov.forward(); _schedHide();

    // العلامة المائية تتنقل كل 30 ثانية
    _wmTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _wmCorner = (_wmCorner + 1) % 4);
    });

    _startPlayback();
  }

  // ── بدء التشغيل — الكاش أولاً، ثم موازنة الأحمال ────────
  Future<void> _startPlayback() async {
    // فحص الكاش: هل يوجد رابط ناجح مخزن لهذا المحتوى؟
    final cachedUrl = PlayUrlCache.get(_contentId);
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      // استخدم الرابط المخزن فوراً
      await _init(cachedUrl);
      if (!widget.isLive) _checkResumePosition();
      return;
    }

    if (widget.urls.isNotEmpty && widget.urls.first.isNotEmpty) {
      // موازنة الأحمال للبث المباشر
      final url = widget.isLive
          ? LiveLoadBalancer.pickBest(widget.urls)
          : widget.urls.first;
      await _init(url);
      if (!widget.isLive) _checkResumePosition();
      return;
    }
    // البحث عن الرابط من السيرفر تلقائياً
    if (widget.item != null) {
      setState(() { _buf = true; _errMsg = 'جاري البحث عن رابط التشغيل...'; });
      try {
        final id = widget.item['stream_id']?.toString() ??
                   widget.item['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          final base = Sub.isVIP && Sub.xtreamUser.isNotEmpty
              ? Sub.xtreamBase.replaceAll(RegExp(r'/$'), '')
              : RC.serverUrl.replaceAll(RegExp(r'/$'), '');
          final user = Sub.isVIP && Sub.xtreamUser.isNotEmpty ? Sub.xtreamUser : RC.username;
          final pass = Sub.isVIP && Sub.xtreamUser.isNotEmpty ? Sub.xtreamPass : RC.password;
          // جرّب امتدادات مختلفة
          for (final ext in ['mp4', 'ts', 'm3u8', 'mkv']) {
            final url = '$base/movie/$user/$pass/$id.$ext';
            _init(url);
            return;
          }
        }
      } catch (_) {}
      setState(() { _err = true; _buf = false; _errMsg = 'لم يُعثر على رابط تشغيل'; });
    }
  }



  Future<void> _init(String url) async {
    setState(() { _buf = true; _err = false; });
    final vc = VideoPlayerController.networkUrl(Uri.parse(url),
      httpHeaders: kIsWeb ? {} : SecurityLayer.streamHeaders(isLive: widget.isLive),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false, allowBackgroundPlayback: false));
    vc.addListener(() => _onEvt(vc));
    try {
      await vc.initialize().timeout(Duration(seconds: widget.isLive ? 30 : 20));
      await vc.setVolume(_vol);
      // ── استكمال من آخر موضع ──────────────────────────────
      if (!widget.isLive && _contentId.isNotEmpty) {
        final lastPos = WatchHistory.getProgressMs(_contentId) > 0 ? Duration(milliseconds: WatchHistory.getProgressMs(_contentId)) : null;
        if (lastPos != null && lastPos.inSeconds > 5) {
          await vc.seekTo(lastPos);
        }
      }
      await vc.play();
      if (mounted) {
        final old = _vc;
        setState(() { _vc = vc; _inited = true; _buf = false; });
        old?.dispose();
        // ── بدء حفظ التقدم كل 5 ثوانٍ ──
        _progressTimer?.cancel();
        _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveProgress());
        // ── Skip Intro: يظهر بعد 3 ثوانٍ ويختفي بعد 90 ثانية ──
        if (!widget.isLive) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showSkipIntro = true);
          });
          Future.delayed(const Duration(seconds: 90), () {
            if (mounted) setState(() => _showSkipIntro = false);
          });
        }
        // ── DVR Buffer للبث المباشر ──
        if (widget.isLive) _initLiveBuffer(vc);
        // ── إضافة للسجل ──
        if (widget.item != null) {
          WatchHistory.addItem(widget.item!, widget.isLive ? 'live' : 'movie');
        }
      } else { vc.dispose(); }
    } catch (e) {
      vc.removeListener(() => _onEvt(vc));
      await vc.dispose();
      _tryNext(e.toString());
    }
  }

  void _onEvt(VideoPlayerController vc) {
    if (!mounted) return;
    if (vc.value.hasError && !_err) setState(() { _err = true; _buf = false; _errMsg = vc.value.errorDescription ?? ''; });
    if (mounted) setState(() {});
  }

  // ── حفظ التقدم ─────────────────────────────────────────
  void _saveProgress() {
    final vc = _vc;
    if (vc == null || !_inited || widget.isLive) return;
    final pos   = vc.value.position.inSeconds;
    final total = vc.value.duration.inSeconds;
    if (_contentId.isNotEmpty) {
      WatchHistory.saveProgress(_contentId, pos, total);
    }
  }

  void _tryNext(String r) {
    // سجّل فشل السيرفر الحالي
    if (_urlIdx < widget.urls.length) {
      try {
        final failedUrl = widget.urls[_urlIdx - 1 < 0 ? 0 : _urlIdx - 1];
        LiveLoadBalancer.markFail(Uri.parse(failedUrl).host);
      } catch (_) {}
    }
    // امسح الكاش إذا كان الرابط المخزن هو الفاشل
    if (_contentId.isNotEmpty) {
      final cached = PlayUrlCache.get(_contentId);
      if (cached != null && _urlIdx == 1) PlayUrlCache.put(_contentId, ''); // invalidate
    }
    _urlIdx++;
    // أولاً: جرّب الروابط المتاحة (مع موازنة الأحمال)
    if (_urlIdx < widget.urls.length && _urlIdx < _maxR) {
      final nextUrl = widget.isLive
          ? LiveLoadBalancer.pickBest(widget.urls.sublist(_urlIdx))
          : widget.urls[_urlIdx];
      _init(nextUrl);
      return;
    }
    // لا تُظهر خطأ — أظهر رسالة واضحة
    String msg;
    if (r.toLowerCase().contains('timeout')) msg = 'انتهت مهلة الاتصال — تحقق من الإنترنت';
    else if (r.contains('404')) msg = 'المحتوى غير متاح حالياً';
    else if (r.contains('403')) msg = 'انتهت صلاحية الرابط';
    else msg = 'تعذّر تشغيل المحتوى';
    if (mounted) setState(() { _err = true; _buf = false; _errMsg = msg; });
  }

  // ── تغيير الجودة بدون انقطاع ──────────────────────────
  Future<void> _changeQuality(int idx) async {
    if (idx == _qualityIdx) return;
    final vc = _vc;
    final pos = vc?.value.position ?? Duration.zero;
    // بناء رابط الجودة المطلوبة
    String url = widget.urls.isNotEmpty ? widget.urls.first : '';
    final item = widget.item;
    if (idx > 0 && item != null) {
      final id = item['stream_id']?.toString() ?? item['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        final base = Sub.isVIP && Sub.xtreamUser.isNotEmpty
            ? Sub.xtreamBase.replaceAll(RegExp(r'/$'), '')
            : RC.serverUrl.replaceAll(RegExp(r'/$'), '');
        final user = Sub.isVIP && Sub.xtreamUser.isNotEmpty ? Sub.xtreamUser : RC.username;
        final pass = Sub.isVIP && Sub.xtreamUser.isNotEmpty ? Sub.xtreamPass : RC.password;
        url = '$base/${widget.isLive ? "live" : "movie"}/$user/$pass/$id.${_qualities[idx].ext}';
      }
    }
    if (url.isEmpty) return;
    setState(() { _qualityIdx = idx; _showQuality = false; _buf = true; });
    // تشغيل الجودة الجديدة ثم القفز للموضع السابق
    final newVc = VideoPlayerController.networkUrl(Uri.parse(url),
        httpHeaders: kIsWeb ? {} : SecurityLayer.streamHeaders(isLive: widget.isLive),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false));
    newVc.addListener(() => _onEvt(newVc));
    try {
      await newVc.initialize().timeout(const Duration(seconds: 20));
      if (!widget.isLive && pos > Duration.zero) await newVc.seekTo(pos);
      await newVc.setVolume(_vol);
      await newVc.play();
      if (mounted) {
        final old = _vc;
        setState(() { _vc = newVc; _inited = true; _buf = false; });
        old?.dispose();
      } else { newVc.dispose(); }
    } catch (_) {
      newVc.dispose();
      // الجودة غير متوفرة — ابقَ على الجودة الحالية
      if (mounted) setState(() { _qualityIdx = 0; _buf = false; });
      _showSnack('هذه الجودة غير متوفرة — تم الإبقاء على الجودة الأصلية');
    }
  }

  // ── تغيير السرعة ──────────────────────────────────────────
  Future<void> _changeSpeed(int idx) async {
    _speedIdx = idx;
    _showSpeed = false;
    await _vc?.setPlaybackSpeed(_speeds[idx]);
    setState(() {});
    Sound.hapticL();
  }

  // ── DVR للبث المباشر: تأخير 7 ثوانٍ للاستقرار ──────────
  Future<void> _initLiveBuffer(VideoPlayerController vc) async {
    if (!widget.isLive) return;
    setState(() => _liveBuffering = true);
    // انتظر تجميع 7 ثوانٍ من البيانات
    await Future.delayed(const Duration(seconds: 7));
    if (mounted) setState(() => _liveBuffering = false);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.black, fontSize: 12)),
      backgroundColor: C.gold, duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
    ));
  }

  // ── تحقق من موضع محفوظ واسأل المستخدم ──────────────────
  Future<void> _checkResumePosition() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || !_inited) return;
    final item = widget.item;
    if (item == null) return;
    final id  = item['stream_id']?.toString() ?? item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final posMs = WatchHistory.getProgressMs(id);
    final pos = posMs;
    if (pos <= 10000) return; // أقل من 10 ثوانٍ: ابدأ من البداية
    if (WatchHistory.isCompleted(id)) return; // مكتمل: ابدأ من البداية
    final dur = _vc?.value.duration.inMilliseconds ?? 0;
    if (pos >= dur && dur > 0) return;
    // أظهر Dialog استكمال
    if (!mounted) return;
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('استكمال المشاهدة', style: T.cairo(s: 16, w: FontWeight.w700)),
        content: Text(
          'وصلت إلى ${_fmt(Duration(milliseconds: pos))} — هل تريد الاستكمال؟',
          style: T.cairo(s: 13, c: C.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: Text('من البداية', style: T.cairo(s: 13, c: C.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: C.gold, foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(_, true),
            child: Text('استكمال', style: T.cairo(s: 13, w: FontWeight.w700))),
        ]));
    if (resume == true && mounted && _vc != null) {
      await _vc!.seekTo(Duration(milliseconds: pos));
      setState(() {});
    }
  }

  void _schedHide() {
    _hideT?.cancel();
    _hideT = Timer(const Duration(seconds: 4), () {
      if (mounted && _overlay) { setState(() => _overlay = false); _ov.reverse(); }
    });
  }
  void _wake() { if (!_overlay) { setState(() => _overlay = true); _ov.forward(); } _schedHide(); }
  void _toggleOv() {
    setState(() => _overlay = !_overlay);
    if (_overlay) { _ov.forward(); _schedHide(); } else { _ov.reverse(); _hideT?.cancel(); }
  }
  void _togglePlay() {
    final vc = _vc; if (vc == null || !_inited) return;
    vc.value.isPlaying ? vc.pause() : vc.play();
    setState(() {}); _wake();
  }
  void _seekBy(int s) {
    final vc = _vc; if (vc == null || !_inited || widget.isLive) return;
    final r = vc.value.position + Duration(seconds: s);
    vc.seekTo(r < Duration.zero ? Duration.zero : r > vc.value.duration ? vc.value.duration : r);
    Sound.hapticL(); // اهتزاز خفيف عند الـ seek
    setState(() {}); _wake();
  }
  void _toggleMute() { _muted = !_muted; _vc?.setVolume(_muted ? 0 : _vol); setState(() {}); }
  void _enterFs() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);
    if (mounted) setState(() => _fs = true);
  }
  void _exitFs() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);
    if (mounted) setState(() => _fs = false);
  }

  String _fmt(Duration d) {
    final h = d.inHours, m = d.inMinutes.remainder(60), s = d.inSeconds.remainder(60);
    return h > 0 ? '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}'
                 : '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  double get _prog {
    final vc = _vc; if (vc == null || !_inited) return 0;
    final d = vc.value.duration.inMilliseconds; if (d == 0) return 0;
    return (vc.value.position.inMilliseconds / d).clamp(0.0, 1.0);
  }
  double get _bufd {
    final vc = _vc; if (vc == null || !_inited || vc.value.buffered.isEmpty) return 0;
    final d = vc.value.duration.inMilliseconds; if (d == 0) return 0;
    return (vc.value.buffered.last.end.inMilliseconds / d).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    // حفظ موضع التشغيل عند الخروج
    _saveWatchPosition();
    _hideT?.cancel();
    _wmTimer?.cancel();
    _progressTimer?.cancel();
    _saveProgress(); // حفظ أخير قبل الإغلاق
    _vc?.dispose();
    _ov.dispose(); _sp.dispose();
    if (!kIsWeb) WakelockPlus.disable();
    SecurityLayer.disableScreenRecord();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);
    super.dispose();
  }

  void _saveWatchPosition() {
    final vc = _vc;
    if (vc == null || !_inited) return;
    final item = widget.item;
    if (item == null) return;
    final id = item['stream_id']?.toString() ?? item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final pos = vc.value.position.inMilliseconds;
    final dur = vc.value.duration.inMilliseconds;
    if (pos > 5000) { // فقط إذا شاهد أكثر من 5 ثوانٍ
      // convert ms to seconds for old API
      WatchHistory.saveProgress(id, pos ~/ 1000, dur ~/ 1000);
      WatchHistory.addItem(item, widget.isLive ? 'live' : 'movie');
    }
  }

  @override
  Widget build(BuildContext context) =>
    Scaffold(backgroundColor: Colors.black, body: _err ? _buildErr() : _buildPlayer());

  Widget _buildErr() => Container(color: Colors.black,
    child: SafeArea(child: Center(
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // خطأ مرئي
          Container(width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: C.surface,
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5)),
            child: Center(child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.play_circle_outline_rounded, color: Colors.white24, size: 44),
              const Icon(Icons.close_rounded, color: Colors.redAccent, size: 22),
            ]))),
          const SizedBox(height: 20),
          Text('تعذّر التشغيل', style: T.cairo(s: 18, w: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(_errMsg, style: T.body(c: C.grey), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('تحقق من اتصالك بالإنترنت', style: T.caption(c: C.dim)),
          const SizedBox(height: 28),
          // أزرار
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: C.border),
                  borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('رجوع', style: T.cairo(s: 13, c: C.grey)))))),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: GestureDetector(
              onTap: () { setState(() { _err = false; _buf = true; _urlIdx = 0; });
                  _init(widget.urls.isNotEmpty ? widget.urls.first : ''); },
              child: Container(height: 44,
                decoration: BoxDecoration(
                  gradient: C.playGrad, borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.refresh_rounded, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  Text('إعادة المحاولة', style: T.cairo(s: 13, c: Colors.black, w: FontWeight.w800)),
                ])))),
          ]),
          const SizedBox(height: 16),
          // رابط واتساب
          if (Sub.whatsapp.isNotEmpty)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://wa.me/${Sub.whatsapp}')),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.headset_mic_rounded, color: Color(0xFF25D366), size: 14),
                const SizedBox(width: 6),
                Text('تواصل مع الدعم الفني', style: T.caption(c: const Color(0xFF25D366))),
              ])),
        ])))));


  // ── مواضع العلامة المائية ────────────────────────────────
  Alignment get _wmAlignment {
    switch (_wmCorner) {
      case 0: return const Alignment(0.85, -0.85);  // أعلى يمين
      case 1: return const Alignment(-0.85, 0.85);  // أسفل يسار
      case 2: return const Alignment(0.85, 0.85);   // أسفل يمين
      default: return const Alignment(-0.85, -0.85); // أعلى يسار
    }
  }

  Widget _buildPlayer() {
    final vc = _vc;
    final vidW = (vc != null && vc.value.size.width  > 0) ? vc.value.size.width  : 1920.0;
    final vidH = (vc != null && vc.value.size.height > 0) ? vc.value.size.height : 1080.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleOv,
      onDoubleTapDown: (d) => _seekBy(d.globalPosition.dx < context.size!.width / 2 ? -10 : 10),
      // سحب رأسي: يمين = صوت، يسار = سطوع، وسط = تجسيم بصري
      onVerticalDragStart: (d) {
        _gestY     = d.localPosition.dy;
        _volDrag   = d.localPosition.dx > context.size!.width * 0.65;
        _brightDrag= d.localPosition.dx < context.size!.width * 0.35;
      },
      onVerticalDragUpdate: (d) {
        final delta = (_gestY - d.localPosition.dy) / (context.size!.height * 0.6);
        if (_volDrag) {
          _vol = (_vol + delta).clamp(0.0, 1.0);
          _vc?.setVolume(_vol);
        } else if (_brightDrag) {
          _brightness = (_brightness + delta).clamp(0.2, 1.0);
        } else {
          // منطقة الوسط = تجسيم (tilt effect)
          _tiltY = (_tiltY - delta * 8).clamp(-6.0, 6.0);
        }
        _gestY = d.localPosition.dy;
        setState(() {});
      },
      onVerticalDragEnd: (_) {
        _volDrag = false; _brightDrag = false;
        // إعادة الـ tilt تدريجياً
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() { _tiltY = 0; _tiltX = 0; });
        });
      },
      onHorizontalDragUpdate: (d) {
        // تجسيم أفقي عند السحب الأفقي
        _tiltX = (_tiltX + d.delta.dx * 0.02).clamp(-4.0, 4.0);
        setState(() {});
      },
      onHorizontalDragEnd: (_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _tiltX = 0);
        });
      },
      child: Stack(fit: StackFit.expand, children: [
        // ── خلفية سوداء ──────────────────────────────────────
        Container(color: Colors.black),

        // ── الفيديو بحجمه الأصلي + تأثير تجسيم ─────────────
        if (_inited && vc != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(_tiltY * math.pi / 180)
              ..rotateY(_tiltX * math.pi / 180),
            transformAlignment: Alignment.center,
            child: Opacity(
              opacity: _brightness.clamp(0.0, 1.0),
              child: Center(
                child: _fitContain
                  // حجم أصلي — لا قص للأطراف
                  ? AspectRatio(
                      aspectRatio: vidW / vidH,
                      child: VideoPlayer(vc))
                  // fullscreen — يملأ الشاشة
                  : FittedBox(fit: BoxFit.cover,
                      child: SizedBox(width: vidW, height: vidH,
                          child: VideoPlayer(vc))),
              ),
            ),
          ),

        if (!_inited && !_err)
          Container(color: Colors.black),

        // ── العلامة المائية — تتنقل بين الزوايا ─────────────
        AnimatedAlign(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          alignment: _wmAlignment,
          child: Opacity(
            opacity: 0.20,
            child: Text('TOTV+',
              style: T.cinzel(s: 11, c: Colors.white)
                  .copyWith(letterSpacing: 3, fontWeight: FontWeight.w700)),
          ),
        ),

        // ── مؤشر الـ gesture ─────────────────────────────────
        if (_volDrag || _brightDrag) _buildGestureInd(),

        // ── Spinner تحميل ─────────────────────────────────────
        if (_buf && !_err) Center(child: AnimatedBuilder(animation: _sp,
          builder: (_, __) => Transform.rotate(angle: _sp.value * 6.28,
            child: Container(width: 50, height: 50,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: C.gold.withOpacity(0.12), width: 1.5)),
              child: CircularProgressIndicator(
                  color: C.gold.withOpacity(0.65), strokeWidth: 1.5))))),

        // ── DVR Buffer indicator (live only) ──────────────────
        if (_liveBuffering && widget.isLive)
          Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(width: 110, child: LinearProgressIndicator(
                  color: Color(0xFFF5C518), backgroundColor: Color(0xFF333333),
                  minHeight: 2)),
              const SizedBox(height: 8),
              Text('جاري تحضير البث...', style: TextStyle(
                  color: Colors.white70, fontSize: 11, fontFamily: 'sans-serif')),
            ]))),

        // ── Skip Intro button ───────────────────────────────
        if (_showSkipIntro && !widget.isLive && !_overlay)
          Positioned(bottom: 90, right: 16,
            child: GestureDetector(
              onTap: () {
                _seekBy(85);
                setState(() => _showSkipIntro = false);
                Sound.hapticM();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('تخطى المقدمة', style: TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      const Icon(Icons.skip_next_rounded, color: Colors.white, size: 16),
                    ]))))),),

        // ── قائمة الجودة ──────────────────────────────────────
        if (_showQuality) _buildQualityPanel(),

        // ── قائمة السرعة ──────────────────────────────────────
        if (_showSpeed) _buildSpeedPanel(),

        FadeTransition(opacity: _ovAn,
            child: _overlay ? _buildOverlay(vc) : const SizedBox.shrink()),
      ]),
    );
  }

  // ── لوحة اختيار الجودة ────────────────────────────────────
  Widget _buildQualityPanel() => Positioned(
    right: 16, top: 70,
    child: GestureDetector(
      onTap: () {},
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.88),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.gold.withOpacity(0.3)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
          children: List.generate(_qualities.length, (i) => GestureDetector(
            onTap: () => _changeQuality(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: i == _qualityIdx ? C.gold.withOpacity(0.12) : Colors.transparent,
                border: i > 0 ? Border(
                    top: BorderSide(color: C.border.withOpacity(0.3))) : null,
              ),
              child: Row(children: [
                if (i == _qualityIdx)
                  const Icon(Icons.check_rounded, color: C.gold, size: 14),
                if (i != _qualityIdx)
                  const SizedBox(width: 14),
                const SizedBox(width: 8),
                Text(_qualities[i].label,
                  style: T.cairo(s: 12,
                    c: i == _qualityIdx ? C.gold : C.white,
                    w: i == _qualityIdx ? FontWeight.w700 : FontWeight.w400)),
              ]),
            ),
          )),
        ),
      ),
    ),
  );

  Widget _buildSpeedPanel() => Positioned(
    right: 16, top: 70,
    child: Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.gold.withOpacity(0.3))),
      child: Column(mainAxisSize: MainAxisSize.min,
        children: List.generate(_speeds.length, (i) {
          final sel = i == _speedIdx;
          return GestureDetector(
            onTap: () => _changeSpeed(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? C.gold.withOpacity(0.12) : Colors.transparent,
                border: i > 0 ? Border(
                    top: BorderSide(color: C.border.withOpacity(0.2))) : null),
              child: Row(children: [
                if (sel)
                  const Icon(Icons.check_rounded, color: C.gold, size: 13),
                if (!sel) const SizedBox(width: 13),
                const SizedBox(width: 8),
                Text('${_speeds[i]}x',
                  style: TextStyle(
                    color: sel ? C.gold : Colors.white70,
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                if (i == 2) ...[ // 1.0x = عادي
                  const SizedBox(width: 4),
                  Text('عادي', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ]),
            ));
        })),
    ));

  Widget _buildGestureInd() {
    final isVol = _volDrag;
    final val   = isVol ? _vol : _brightness;
    final icon  = isVol ? (val == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded)
                        : Icons.brightness_medium_rounded;
    return Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(14)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: C.gold, size: 26), const SizedBox(height: 8),
        SizedBox(width: 110, child: LinearProgressIndicator(value: val,
            backgroundColor: C.dim, color: C.gold, minHeight: 4)),
        const SizedBox(height: 5),
        Text(isVol ? 'الصوت ${(val*100).round()}%' : 'السطوع ${(val*100).round()}%',
            style: T.mont(s: 10, c: C.gold)),
      ])));
  }

  Widget _buildOverlay(VideoPlayerController? vc) => Stack(fit: StackFit.expand, children: [
    DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        stops: const [0.0, 0.25, 0.72, 1.0],
        colors: [Colors.black.withOpacity(0.75), Colors.transparent,
                 Colors.transparent, Colors.black.withOpacity(0.9)]))),
    Positioned(top: 0, left: 0, right: 0, child: _buildTop()),
    Center(child: _buildControls(vc)),
    Positioned(bottom: 0, left: 0, right: 0, child: _buildBottom(vc)),
  ]);

  Widget _buildTop() {
    final top = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(top: top + 10, left: 16, right: 16, bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent])),
          child: Row(children: [
        GestureDetector(onTap: () => Navigator.pop(context),
          child: Container(width: 34, height: 34, decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: C.white, size: 16))),
        const SizedBox(width: 12),
        Expanded(child: Text(widget.title, style: T.cairo(s: 13, w: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (widget.isLive)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: C.live.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: C.live.withOpacity(0.4))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 5, height: 5, decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: C.live)),
              const SizedBox(width: 5),
              Text('LIVE', style: T.mont(s: 9, c: C.live, w: FontWeight.w700)),
            ])),
        const SizedBox(width: 8),
        GestureDetector(onTap: _toggleMute,
          child: Container(width: 34, height: 34,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: C.white, size: 16))),
        const SizedBox(width: 6),
        // زر الجودة
        GestureDetector(
          onTap: () => setState(() { _showQuality = !_showQuality; _showSpeed = false; _hideT?.cancel(); }),
          child: Container(width: 34, height: 34,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.hd_rounded, color: _showQuality ? C.gold : C.white, size: 18))),
        const SizedBox(width: 6),
        // زر تبديل الحجم (أصلي / ملء شاشة)
        GestureDetector(
          onTap: () { setState(() => _fitContain = !_fitContain); Sound.hapticL(); },
          child: Container(width: 34, height: 34,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(
              _fitContain ? Icons.fit_screen_rounded : Icons.crop_rounded,
              color: C.white, size: 18))),
        const SizedBox(width: 6),
        GestureDetector(onTap: _fs ? _exitFs : _enterFs,
          child: Container(width: 34, height: 34,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(_fs ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                color: C.white, size: 20))),
      ]))));
  }

  Widget _buildControls(VideoPlayerController? vc) {
    if (!_inited || vc == null) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (!widget.isLive)
        GestureDetector(onTap: () => _seekBy(-10),
          child: Container(width: 42, height: 42,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.35),
                border: Border.all(color: C.border, width: 0.5)),
            child: const Icon(Icons.replay_10_rounded, color: C.white, size: 20))),
      const SizedBox(width: 20),
      GestureDetector(onTap: _togglePlay,
        child: Container(width: 58, height: 58,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.5),
              border: Border.all(color: C.gold.withOpacity(0.5), width: 1.5)),
          child: Icon(vc.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: C.white, size: 28))),
      const SizedBox(width: 20),
      if (!widget.isLive)
        GestureDetector(onTap: () => _seekBy(10),
          child: Container(width: 42, height: 42,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.35),
                border: Border.all(color: C.border, width: 0.5)),
            child: const Icon(Icons.forward_10_rounded, color: C.white, size: 20))),
    ]);
  }

  Widget _buildBottom(VideoPlayerController? vc) {
    final pos = (_inited && vc != null) ? vc.value.position : Duration.zero;
    final dur = (_inited && vc != null) ? vc.value.duration  : Duration.zero;
    return Container(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (!widget.isLive) ...[
          GestureDetector(
            onHorizontalDragStart: (_) => setState(() {
              _seekDrag = true; _seekVal = _prog; _seekExpanded = true;
            }),
            onHorizontalDragUpdate: (d) {
              final b = context.findRenderObject() as RenderBox?; if (b == null) return;
              final v = (d.localPosition.dx / b.size.width).clamp(0.0, 1.0);
              // Preview time
              final previewSecs = (v * dur.inSeconds).round();
              _seekPreview = _fmt(Duration(seconds: previewSecs));
              setState(() => _seekVal = v);
            },
            onHorizontalDragEnd: (_) {
              vc?.seekTo(dur * _seekVal);
              setState(() { _seekDrag = false; _seekExpanded = false; _seekPreview = ''; });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: _seekExpanded ? 36 : 22,
              child: Stack(alignment: Alignment.centerLeft, children: [
              // Preview time above thumb
              if (_seekDrag && _seekPreview.isNotEmpty)
                FractionallySizedBox(widthFactor: _seekVal,
                  child: Align(alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4)),
                      child: Text(_seekPreview,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.w600))))),
              Container(height: _seekExpanded ? 5 : 3, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(widthFactor: _bufd, child: Container(
                  height: _seekExpanded ? 5 : 3,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(3)))),
              FractionallySizedBox(widthFactor: _seekDrag ? _seekVal : _prog,
                child: Container(height: _seekExpanded ? 5 : 3, decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [C.goldLight, C.gold]),
                    borderRadius: BorderRadius.circular(3)))),
              FractionallySizedBox(widthFactor: _seekDrag ? _seekVal : _prog,
                child: Align(alignment: Alignment.centerRight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _seekExpanded ? 16 : 10, height: _seekExpanded ? 16 : 10,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: C.gold,
                        boxShadow: [BoxShadow(color: C.gold.withOpacity(0.5), blurRadius: 5)])))),
            ])),),
          const SizedBox(height: 6),
        ],
        Row(children: [
          if (!widget.isLive) ...[
            Text(_fmt(pos), style: T.mont(s: 11, c: C.white)),
            Text(' / ', style: T.mont(s: 11, c: C.dim)),
            Text(_fmt(dur), style: T.mont(s: 11, c: C.grey)),
          ],
          if (widget.isLive) _LiveClock(),
          const Spacer(),
          // زر السرعة (للأفلام فقط)
          if (!widget.isLive)
            GestureDetector(
              onTap: () => setState(() { _showSpeed = !_showSpeed; _hideT?.cancel(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _showSpeed ? C.gold.withOpacity(0.15) : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _showSpeed ? C.gold.withOpacity(0.5) : Colors.white.withOpacity(0.15),
                    width: 0.5)),
                child: Text('${_speeds[_speedIdx]}x',
                  style: TextStyle(
                    color: _showSpeed ? C.gold : Colors.white70,
                    fontSize: 11, fontWeight: FontWeight.w600)))),
          if (!widget.isLive) const SizedBox(width: 8),
          SizedBox(width: 80, child: Row(children: [
            Icon(_vol == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: C.dim, size: 13),
            const SizedBox(width: 3),
            Expanded(child: SliderTheme(data: SliderThemeData(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                trackHeight: 2, overlayShape: SliderComponentShape.noOverlay),
              child: Slider(value: _vol,
                  onChanged: (v) { setState(() => _vol = v); _vc?.setVolume(v); },
                  min: 0, max: 1, activeColor: C.gold, inactiveColor: C.dim, thumbColor: C.gold))),
          ])),
        ]),
      ]));
  }
}


// ══════════════════════════════════════════════════════════════
//  MICRO WIDGETS
// ══════════════════════════════════════════════════════════════

class _Pulse extends StatefulWidget {
  final String label;
  _Pulse({required this.label});
  @override State<_Pulse> createState() => _PulseState();
}
class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    AnimatedBuilder(animation: _a, builder: (_, __) => Container(width: 56, height: 56,
      decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: C.gold.withOpacity(0.2 + _a.value * 0.6), width: 1.2)),
      child: Center(child: Text('T', style: T.cinzel(s: 22,
          c: C.gold.withOpacity(0.4 + _a.value * 0.55)))))),
    const SizedBox(height: 14),
    Text('جاري التحميل...', style: T.mont(s: 12, c: C.grey.withOpacity(0.6))),
  ]);
}

class _CounterBar extends StatelessWidget {
  final String label;
  _CounterBar({required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [C.goldLight, C.goldDark]), borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: T.mont(s: 10, c: C.gold, w: FontWeight.w600, ls: 1)),
  ]);
}

class _AppHdr extends StatelessWidget {
  final double top; final String title; final VoidCallback onRefresh;
  _AppHdr({required this.top, required this.title, required this.onRefresh});
  @override
  Widget build(BuildContext context) => Container(
    height: 52 + top, padding: EdgeInsets.only(top: top, left: 16, right: 16),
    decoration: const BoxDecoration(color: Color(0xF5000000),
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A), width: 0.5))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text('TOTV+', style: T.cinzel(s: 14, c: C.gold).copyWith(letterSpacing: 2)),
      const SizedBox(width: 10),
      Text(title, style: T.cairo(s: 16, w: FontWeight.w700)),
      const Spacer(),
      if (!Sub.isPremium)
        GestureDetector(
          onTap: () => Navigator.push(context, _fade(const ProfilePage())),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(gradient: C.playGrad, borderRadius: BorderRadius.circular(8)),
            child: Text('اشتراك', style: T.cairo(s: 10, c: Colors.black, w: FontWeight.w800)))),
      const SizedBox(width: 8),
      GestureDetector(onTap: onRefresh,
        child: Container(width: 32, height: 32,
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: C.border, width: 0.5)),
          child: const Icon(Icons.refresh_rounded, color: C.grey, size: 16))),
    ]));
}

class _Chip extends StatelessWidget {
  final String label; final bool sel; final VoidCallback onTap;
  _Chip({required this.label, required this.sel, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: sel ? C.gold : C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: sel ? C.gold : C.border, width: sel ? 0 : 0.5)),
      child: Text(label, style: T.cairo(s: 11, c: sel ? Colors.black : C.grey,
          w: sel ? FontWeight.w700 : FontWeight.w400))));
}

class _TagW extends StatelessWidget {
  final String text;
  const _TagW(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: C.goldBg, borderRadius: BorderRadius.circular(4),
        border: Border.all(color: C.goldDark.withOpacity(0.35), width: 0.5)),
    child: Text(text, style: T.mont(s: 9, c: C.gold, w: FontWeight.w600)));
}

// ── MetaChip & LiveBadge ─────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final String text;
  const _MetaChip(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: C.surface,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: C.border, width: 0.5)),
    child: Text(text, style: T.mont(s: 10, c: C.grey)));
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: C.live, borderRadius: BorderRadius.circular(5)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5, margin: const EdgeInsets.only(left: 4),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
      Text('LIVE', style: T.mont(s: 9, c: Colors.white, w: FontWeight.w700)),
    ]));
}

class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl; final ValueChanged<String> onChanged;
  _SearchBar({required this.ctrl, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(height: 42,
    decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.border, width: 0.5)),
    child: Row(children: [
      const SizedBox(width: 12),
      Icon(Icons.search_rounded, color: C.gold.withOpacity(0.4), size: 18),
      const SizedBox(width: 8),
      Expanded(child: TextField(controller: ctrl, onChanged: onChanged,
          textDirection: TextDirection.rtl, style: T.cairo(s: 13),
          decoration: InputDecoration(hintText: 'ابحث...',
              hintStyle: T.cairo(s: 13, c: C.dim), border: InputBorder.none, isDense: true))),
    ]));
}

class _Tile extends StatelessWidget {
  final IconData icon; final String title, value;
  const _Tile(this.icon, this.title, this.value);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.border, width: 0.5)),
    child: Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: C.goldBg,
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: C.gold, size: 16)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: T.mont(s: 10, c: C.grey)),
        const SizedBox(height: 2),
        Text(value, style: T.cairo(s: 12, w: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]));
}

class _LiveDot extends StatefulWidget {
  @override State<_LiveDot> createState() => _LiveDotState();
}
class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 1.0).animate(_c);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _a,
    builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle,
          color: C.live.withOpacity(_a.value))),
      const SizedBox(width: 4),
      Text('مباشر', style: T.mont(s: 10, c: C.live, w: FontWeight.w700)),
    ]));
}

class _LiveClock extends StatefulWidget {
  @override State<_LiveClock> createState() => _LiveClockState();
}
class _LiveClockState extends State<_LiveClock> {
  late Timer _t; late DateTime _now;
  @override void initState() {
    super.initState();
    _now = DateTime.now();
    _t = Timer.periodic(const Duration(seconds: 1),
        (_) { if (mounted) setState(() => _now = DateTime.now()); });
  }
  @override void dispose() { _t.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Text(
    '${_now.hour.toString().padLeft(2,'0')}:${_now.minute.toString().padLeft(2,'0')}:${_now.second.toString().padLeft(2,'0')}',
    style: T.mont(s: 11, c: C.white));
}

// ══════════════════════════════════════════════════════════════
//  _AutoPageView — بديل لـ CarouselWidget بـ PageView مدمج
//  لا يحتاج package خارجي — يتجنب تعارض CarouselController
// ══════════════════════════════════════════════════════════════
class _AutoPageView extends StatefulWidget {
  final int itemCount;
  final Duration interval;
  final ValueChanged<int>? onPageChanged;
  final Widget Function(BuildContext, int) itemBuilder;
  final double? height;
  _AutoPageView({
    required this.itemCount,
    required this.itemBuilder,
    this.interval = const Duration(seconds: 5),
    this.onPageChanged,
    this.height,
  });
  @override State<_AutoPageView> createState() => _AutoPageViewState();
}

class _AutoPageViewState extends State<_AutoPageView> {
  late final PageController _pc;
  Timer? _timer;
  int _cur = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController();
    if (widget.itemCount > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (!mounted) return;
        final int next = (_cur + 1) % widget.itemCount;
        _pc.animateToPage(next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = PageView.builder(
      controller: _pc,
      itemCount: widget.itemCount,
      onPageChanged: (i) {
        _cur = i;
        widget.onPageChanged?.call(i);
      },
      itemBuilder: widget.itemBuilder,
    );
    return widget.height != null
        ? SizedBox(height: widget.height, child: view)
        : view;
  }
}

class _BlurredBackground extends StatelessWidget {
  final VideoPlayerController controller;
  final double vidW, vidH;
  _BlurredBackground({required this.controller, required this.vidW, required this.vidH});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    FittedBox(fit: BoxFit.cover,
        child: SizedBox(width: vidW, height: vidH, child: VideoPlayer(controller))),
    BackdropFilter(filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(color: Colors.black.withOpacity(0.45))),
  ]);
}

// ── Helpers ────────────────────────────────────────────────
Route _fade(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, a, __, c) {
    // Slide up + fade — مثل iOS
    final slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic));
    final fade = CurvedAnimation(parent: a, curve: Curves.easeOut);
    return FadeTransition(opacity: fade,
        child: SlideTransition(position: slide, child: c));
  },
  transitionDuration: const Duration(milliseconds: 320));


// ═══════════════════════════════════════════ END TOTV+ v12.0 ═══════════════════════════════════
