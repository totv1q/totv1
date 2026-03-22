// ═══════════════════════════════════════════════════════════
//  TOTV+  v12.0  —  main.dart  (TOD-STYLE REDESIGN)
//
//  ✅ تصميم TOD الاحترافي — Hero Fullscreen + أقسام بالفئات
//  ✅ شاشة سوداء + اسم التطبيق فقط عند الفتح (Android)
//  ✅ منع التسجيل فقط داخل المشغل
//  ✅ حظر المستخدمين بمعرف الجهاز (Firestore)
//  ✅ تحقق من الإصدار — شاشة تحديث إجبارية
//  ✅ Info Sheet بتصميم TOD (Backdrop + معلومات + زر تشغيل/اشتراك)
//  ✅ زر اشتراك للمحتوى 2025/2026
//  ✅ Worker يُرسل روابط مباشرة بدون إضافة https
//  ✅ أقسام: الرئيسية / مباشر / أفلام / مسلسلات / رياضة / حسابي
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
const kAppVersion = 12;    // رقم الإصدار الحالي — يُقارن بـ Remote Config
const kUpdateUrl  = 'https://hamza123123123.github.io/totv/#';
const kProxyBase  = 'https://totv-proxy.haedirasso.workers.dev';

// ─────────────────────────────────────────────────────────
//  COLORS — TOD Style: أسود + ذهبي
// ─────────────────────────────────────────────────────────
class C {
  static const bg       = Color(0xFF000000);
  static const bg2      = Color(0xFF0D0D0D);
  static const surface  = Color(0xFF161616);
  static const card     = Color(0xFF1A1A1A);
  static const border   = Color(0xFF2A2A2A);
  static const white    = Color(0xFFFFFFFF);
  static const grey     = Color(0xFF999999);
  static const dim      = Color(0xFF555555);
  static const live     = Color(0xFFE53935);
  static const gold     = Color(0xFFF5C518);   // IMDb yellow
  static const goldLight= Color(0xFFFFD740);
  static const goldDark = Color(0xFFFFAB00);
  static const goldBg   = Color(0x18F5C518);
  static const accent   = Color(0xFFF5C518);   // TOD accent = ذهبي

  static const goldGrad = LinearGradient(
    colors: [goldLight, gold, goldDark],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const playGrad = LinearGradient(
    colors: [Color(0xFFFFD740), Color(0xFFFFAB00)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const heroGrad = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    stops: [0.0, 0.4, 0.75, 1.0],
    colors: [Color(0x00000000), Color(0x22000000), Color(0xBB000000), Color(0xFF000000)]);
}

// ─────────────────────────────────────────────────────────
//  TEXT
// ─────────────────────────────────────────────────────────
class T {
  static TextStyle mont({double s = 14, FontWeight w = FontWeight.w400,
      Color c = C.white, double ls = 0}) =>
      GoogleFonts.montserrat(fontSize: s, fontWeight: w, color: c, letterSpacing: ls);

  static TextStyle cairo({double s = 14, FontWeight w = FontWeight.w400, Color c = C.white}) =>
      TextStyle(fontFamily: 'Cairo', fontSize: s, fontWeight: w, color: c);

  static TextStyle cinzel({double s = 14, Color c = C.gold, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.cinzel(fontSize: s, fontWeight: w, color: c);
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
  static bool get isTV      => !kIsWeb && defaultTargetPlatform == TargetPlatform.android && isTablet;
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
        'proxy_url':     kProxyBase,
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
    _proxyUrl     = _s('proxy_url',    kProxyBase);
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
        .map((e) => '\${e.key}=\${Uri.encodeComponent(e.value)}').join('&');
    final proxy = _proxyUrl.isNotEmpty ? _proxyUrl : kProxyBase;
    return '\$proxy?\$query';
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

  // ── Internal Xtream access (package:* only) ──────────────────
  static String get _xtreamUser => _xUser;
  static String get _xtreamPass => _xPass;
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
  static final _dio  = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8)));
  static final _cache = HashMap<String, Map<String, String>>();

  static String poster(String path, {String size = 'w500'}) =>
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
          'poster':    poster(best['poster_path']?.toString() ?? ''),
          'poster_sm': thumb(best['poster_path']?.toString() ?? ''),
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
    if (t == null || DateTime.now().difference(t).inMinutes > RC.cacheMinutes) return null;
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

// ─────────────────────────────────────────────────────────
//  API
// ─────────────────────────────────────────────────────────
class Api {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 25),
    headers: {
      'Accept': 'application/json',
    },
  ))..interceptors.add(_RetryInterceptor());

  static Future<List<dynamic>> getList(String action,
      {bool force = false, Map<String, dynamic>? extra}) async {
    final cacheKey = '\${Sub.isVIP ? "vip_\${Sub._xtreamBase}" : RC.proxyUrl}_\${action}_\${extra?.toString() ?? ''}';
    final cacheKey = '${Sub.isVIP ? '' : RC.proxyUrl}_${action}_${extra?.toString() ?? ''}';
    if (!force) {
      final cached = ListCache.get(cacheKey);
      if (cached != null) return cached;
    }
    try {
      final url = Sub.buildApiUrl(action, extra);
      final r   = await _dio.get(url);
      List<dynamic> list;
      if (r.data is List)
        list = List<dynamic>.from(r.data as List);
      else if (r.data is Map && r.data['data'] is List)
        list = List<dynamic>.from(r.data['data'] as List);
      else return [];
      if (!Sub.isVIP && !Sub.isPremium && extra == null) list = _guestFilter(list, action);
      else if (Sub.isNormal && extra == null) list = _guestFilter(list, action);
      ListCache.put(cacheKey, list);
      return list;
    } catch (e) {
      debugPrint('API Error [$action]: $e');
      return [];
    }
  }

  static Future<Map<String, List<dynamic>>> batchFetch() async {
    final futures = {
      'movies':      getList('get_vod_streams'),
      'series':      getList('get_series'),
      'live':        getList('get_live_streams'),
      'movie_cats':  getList('get_vod_categories'),
      'series_cats': getList('get_series_categories'),
      'live_cats':   getList('get_live_categories'),
    };
    final results = <String, List<dynamic>>{};
    await Future.wait(futures.entries.map((e) async {
      results[e.key] = await e.value;
    }));
    return results;
  }

  static List<dynamic> _guestFilter(List<dynamic> list, String action) {
    if (action == 'get_live_streams') {
      const sportsKw = ['bein','sport','رياض','كور','arena','eurosport','football',
                        'gulf','خليج','دوري','ليغ','league'];
      // 4 قنوات رياضية
      final sports = list.where((item) {
        final n = '\${item["name"]??""} \${item["category_name"]??""}'.toLowerCase();
        return sportsKw.any((k) => n.contains(k));
      }).take(4).toList();
      // 26 قناة متنوعة (عربية وعراقية)
      const arabKw = ['عراق','iraq','عرب','arab','mbc','bbc','cnn','الجزيرة',
                      'الأولى','قناة','channel','rotana','osn'];
      final arab = list.where((item) {
        final n = '\${item["name"]??""} \${item["category_name"]??""}'.toLowerCase();
        return !sportsKw.any((k) => n.contains(k)) &&
               arabKw.any((k) => n.contains(k));
      }).take(26).toList();
      final combined = [...sports, ...arab];
      return combined.take(30).toList();
    }
    // للأفلام: مشترك عادي يرى 1000 فيلم
    if (Sub.isNormal && action == 'get_vod_streams') return list.take(1000).toList();
    if (Sub.isNormal) return list;
    // مجاني: محتوى محدود
    return list.take(RC.guestLimit).toList();
  }

  static Future<Map<String, dynamic>> getSeriesInfo(String sid) async {
    final cached = SeriesInfoCache.get(sid);
    if (cached != null) return cached;
    try {
      final url = RC.buildApiUrl('get_series_info', {'series_id': sid});
      final r   = await _dio.get(url);
      if (r.data is Map) {
        final d = Map<String, dynamic>.from(r.data as Map);
        SeriesInfoCache.put(sid, d);
        return d;
      }
    } catch (_) {}
    return {};
  }

  static List<String> liveUrls(dynamic item) {
    final id = item['stream_id'].toString();
    if (kIsWeb) return [RC.streamUrl('live', id, 'm3u8')];
    return [RC.streamUrl('live', id, 'ts'), RC.streamUrl('live', id, 'm3u8')];
  }

  static List<String> movieUrls(dynamic item) {
    final id  = item['stream_id'].toString();
    final ext = (item['container_extension']?.toString() ?? 'mp4').toLowerCase();
    return [
      if (kIsWeb) RC.streamUrl('movie', id, 'mp4'),
      if (!kIsWeb) RC.streamUrl('movie', id, ext),
      RC.streamUrl('movie', id, 'mp4'),
      if (!kIsWeb) RC.streamUrl('movie', id, 'mkv'),
      if (!kIsWeb) RC.streamUrl('movie', id, 'ts'),
    ].toSet().toList();
  }

  static List<String> episodeUrls(dynamic ep) {
    final id  = ep['id'].toString();
    final ext = (ep['container_extension']?.toString() ?? 'mp4').toLowerCase();
    return [RC.streamUrl('series', id, ext), RC.streamUrl('series', id, 'mp4')];
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
String _imgUrl(String url) {
  if (!kIsWeb || url.isEmpty) return url;
  // الصور من blogger/darlogo تحتاج CORS proxy
  if (url.contains('blogger.googleusercontent.com') ||
      url.contains('darlogo.xyz') ||
      url.contains('blogspot.com') ||
      url.startsWith('http://')) {
    final proxy = RC.proxyUrl.replaceAll(RegExp(r'/\$'), '');
    return '$proxy/img/?url=${Uri.encodeComponent(url)}';
  }
  return url;
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

  static const _kMovies = 'totv_cache_movies_v3';
  static const _kSeries = 'totv_cache_series_v3';
  static const _kLive   = 'totv_cache_live_v3';
  static const _kMCats  = 'totv_cache_mcats_v3';
  static const _kSCats  = 'totv_cache_scats_v3';
  static const _kLCats  = 'totv_cache_lcats_v3';
  static const _kTime   = 'totv_cache_time_v3';

  static Future<void> loadAll({bool force = false}) async {
    if (_loading) return;
    if (isLoaded && !force) return;
    _loading = true;
    if (!force) await _loadFromDisk();
    try {
      final data = await Api.batchFetch();
      allMovies  = data['movies']      ?? allMovies;
      allSeries  = data['series']      ?? allSeries;
      allLive    = data['live']        ?? allLive;
      movieCats  = data['movie_cats']  ?? movieCats;
      seriesCats = data['series_cats'] ?? seriesCats;
      liveCats   = data['live_cats']   ?? liveCats;
      isLoaded   = true;
      _saveToDisk();
    } catch (_) {
      isLoaded = true;
    } finally { _loading = false; }
  }

  static Future<void> _loadFromDisk() async {
    try {
      final p = await SharedPreferences.getInstance();
      final t = p.getInt(_kTime) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - t < 6 * 3600 * 1000) {
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
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kMovies, _enc(allMovies.take(500).toList()));
      await p.setString(_kSeries, _enc(allSeries.take(500).toList()));
      await p.setString(_kLive,   _enc(allLive.take(500).toList()));
      await p.setString(_kMCats,  _enc(movieCats));
      await p.setString(_kSCats,  _enc(seriesCats));
      await p.setString(_kLCats,  _enc(liveCats));
      await p.setInt(_kTime, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
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
    try {
      if (_p == null) await init();
      await _p?.setVolume(1.0);
      await _p?.play(AssetSource('sounds/cha_ching.mp3'));
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
  Plat.detect();

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
  await Future.wait([RC.init(), Sub.load(), WL.load(), Sound.init()]);
    // مراقبة تحديثات التكوين من Firebase (buyUrl, maintenance, etc)
    FirebaseFirestore.instance
        .collection('app_config').doc('subscription')
        .snapshots().listen((snap) {
      if (snap.exists) {
        final url = snap.data()?['buy_url']?.toString() ?? '';
        if (url.isNotEmpty) Sub.updateBuyUrl(url);
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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
  ]);

  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize      = 1000;

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
        fontFamily: 'Cairo', bodyColor: C.white, displayColor: C.white),
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
    try {
      await Future.wait([AppState.loadAll(), ]);
    } catch (_) {}
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
    // تحميل بيانات في الخلفية إذا لم تُحمَّل بعد
    if (!AppState.isLoaded) AppState.loadAll();
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
    const _Tab(Icons.sensors_outlined,       Icons.sensors_rounded,       'مباشر'),
    const _Tab(Icons.movie_outlined,         Icons.movie_rounded,         'أفلام'),
    const _Tab(Icons.tv_outlined,            Icons.tv_rounded,            'مسلسلات'),
    const _Tab(Icons.sports_soccer_outlined, Icons.sports_soccer_rounded, 'رياضة'),
    const _Tab(Icons.person_outline_rounded, Icons.person_rounded,        'حسابي'),
  ];

  List<Widget> _buildPages() => [
    const HomePage(),
    const LivePage(),
    ContentPage(type: 'movie',  label: 'أفلام'),
    ContentPage(type: 'series', label: 'مسلسلات'),
    const SportsPage(),
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
          height: 58 + bot,
          decoration: const BoxDecoration(
            color: Color(0xF5050505),
            border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 0.5))),
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
    if (!AppState.isLoaded) await AppState.loadAll();
    final featured = [...AppState.allMovies.take(6), ...AppState.allSeries.take(6)];
    featured.shuffle();
    final heroes = <_HeroItem>[];
    for (final item in featured.take(8)) {
      final isTv  = AppState.allSeries.contains(item);
      final name  = item['name']?.toString() ?? '';
      final icon  = item['stream_icon']?.toString() ?? item['cover']?.toString() ?? '';
      final tmdb  = await TMDB.search(name, isTv: isTv);
      final year  = tmdb['year'] ?? '';
      heroes.add(_HeroItem(
        item: item, isTv: isTv,
        backdrop: tmdb['backdrop']?.isNotEmpty == true ? tmdb['backdrop']! : icon,
        poster:   tmdb['poster_sm']?.isNotEmpty == true ? tmdb['poster_sm']! : icon,
        title:    tmdb['title']  ?? name,
        overview: tmdb['overview'] ?? '',
        rating:   tmdb['rating']   ?? '',
        year:     year,
        cast:     tmdb['cast']     ?? '',
        director: tmdb['director'] ?? '',
        needsSub: _isNew(year),
      ));
    }
    if (mounted) setState(() { _heroes = heroes; _busy = false; });
  }

  // المحتوى الجديد (2025/2026) يحتاج اشتراك
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
    if (_busy) return Scaffold(backgroundColor: C.bg,
        body: Center(child: _Pulse(label: 'TOTV+')));

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

            // ── أحدث الأفلام (landscape cards) ──
            if (AppState.allMovies.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHdr(title: 'أحدث الأفلام', onMore: () {})),
              SliverToBoxAdapter(child: _LandscapeRow(
                  items: AppState.allMovies.take(15).toList(),
                  type: 'movie', onTap: _openInfo)),
            ],

            // ── أحدث المسلسلات (portrait cards) ──
            if (AppState.allSeries.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHdr(title: 'أحدث المسلسلات', onMore: () {})),
              SliverToBoxAdapter(child: _PortraitRow(
                  items: AppState.allSeries.take(15).toList(),
                  type: 'series', onTap: _openInfo)),
            ],

            // ── البث المباشر ──
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
        urls: Api.movieUrls(h.item), title: h.title)));
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
                ? CachedNetworkImage(imageUrl: h2.backdrop, fit: BoxFit.cover,
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
  _TODInfoSheet({required this.item, required this.type,
      required this.backdrop, required this.poster, required this.title,
      required this.overview, required this.rating, required this.year,
      required this.cast, required this.director, required this.needsSub});
  @override State<_TODInfoSheet> createState() => _TODInfoSheetState();
}

class _TODInfoSheetState extends State<_TODInfoSheet> {
  bool _inWl = false;
  @override void initState() { super.initState(); _inWl = WL.has(widget.item); }

  void _play() {
    Navigator.pop(context);
    Ads.show();
    if (widget.type == 'series') {
      Navigator.push(context, _fade(SeriesDetailPage(series: widget.item)));
      return;
    }
    final urls = widget.type == 'live'
        ? Api.liveUrls(widget.item)
        : Api.movieUrls(widget.item);
    Navigator.push(context, _fade(PlayerPage(urls: urls, title: widget.title,
        isLive: widget.type == 'live')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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

          SizedBox(height: 220, width: double.infinity,
            child: ClipRRect(borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: widget.backdrop.isNotEmpty
                  ? CachedNetworkImage(imageUrl: widget.backdrop, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: C.surface))
                  : Container(color: C.surface))),
          Container(height: 220, decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, const Color(0xFF111111).withOpacity(0.98)]))),
        ]),

        // ── Content ───────────────────────────────────────
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title + meta
            Text(widget.title, style: T.cairo(s: 20, w: FontWeight.w800),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            // Meta row: year • rating • HD
            Wrap(spacing: 8, children: [
              if (widget.year.isNotEmpty)
                Text(widget.year.length >= 4 ? widget.year.substring(0,4) : widget.year,
                    style: T.mont(s: 12, c: C.grey)),
              if (widget.rating.isNotEmpty && widget.rating != '0.0')
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: C.gold, size: 13),
                  const SizedBox(width: 3),
                  Text(widget.rating, style: T.mont(s: 12, c: C.gold)),
                ]),
              if (widget.type == 'live')
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: C.live, borderRadius: BorderRadius.circular(4)),
                  child: Text('LIVE', style: T.mont(s: 9, c: Colors.white, w: FontWeight.w700))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(border: Border.all(color: C.grey.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('HD', style: T.mont(s: 9, c: C.grey))),
              if (widget.needsSub)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(4)),
                  child: Text('حصري', style: T.mont(s: 9, c: Colors.black, w: FontWeight.w700))),
            ]),

            // Overview
            if (widget.overview.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(widget.overview, style: T.mont(s: 12, c: C.grey),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
            ],

            // Cast + Director
            if (widget.director.isNotEmpty) ...[
              const SizedBox(height: 8),
              RichText(text: TextSpan(children: [
                TextSpan(text: 'إخراج: ', style: T.cairo(s: 12, c: C.gold)),
                TextSpan(text: widget.director, style: T.cairo(s: 12, c: C.grey)),
              ])),
            ],
            if (widget.cast.isNotEmpty) ...[
              const SizedBox(height: 4),
              RichText(text: TextSpan(children: [
                TextSpan(text: 'طاقم العمل: ', style: T.cairo(s: 12, c: C.gold)),
                TextSpan(text: widget.cast, style: T.cairo(s: 12, c: C.grey)),
              ])),
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
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, _fade(PlayerPage(
                          urls: widget.isLive
                              ? Api.liveUrls(widget.item)
                              : Api.movieUrls(widget.item),
                          title: widget.title,
                          isLive: widget.isLive,
                        )));
                      },
                      child: Container(
                        height: 52, width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF5C518), Color(0xFFFFAB00)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                          SizedBox(width: 8),
                          Text('تشغيل', style: TextStyle(color: Colors.black,
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

  @override void initState() { super.initState(); _load(); }

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
  final String title; final VoidCallback onMore;
  _SectionHdr({required this.title, required this.onMore});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
    child: Row(children: [
      Text(title, style: T.cairo(s: 16, w: FontWeight.w700)),
      const Spacer(),
      GestureDetector(onTap: onMore,
        child: Text('عرض الكل', style: T.cairo(s: 12, c: C.gold))),
    ]));
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
                img.isNotEmpty
                    ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, memCacheHeight: 250,
                        placeholder: (_, __) => Container(color: C.surface),
                        errorWidget: (_, __, ___) => _NoImg(item['name']?.toString() ?? ''))
                    : _NoImg(item['name']?.toString() ?? ''),
                DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)]))),
                Positioned(bottom: 6, left: 8, right: 8,
                  child: Text(item['name'] ?? '', style: T.cairo(s: 10, w: FontWeight.w600),
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
                    ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, width: 100,
                        memCacheHeight: 300,
                        placeholder: (_, __) => Container(color: C.surface),
                        errorWidget: (_, __, ___) => _NoImg(item['name']?.toString() ?? ''))
                    : _NoImg(item['name']?.toString() ?? ''))),
              const SizedBox(height: 4),
              Text(item['name'] ?? '', style: T.cairo(s: 10),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])));
      }));
}

// ── Live Channel Row ───────────────────────────────────────
class _LiveChannelRow extends StatelessWidget {
  final List<dynamic> items;
  final void Function(dynamic, String) onTap;
  _LiveChannelRow({required this.items, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(height: 80,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length > 20 ? 20 : items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final img  = item['stream_icon']?.toString() ?? '';
        return GestureDetector(
          onTap: () => onTap(item, 'live'),
          child: Container(
            width: 72, margin: const EdgeInsets.only(right: 8),
            child: Column(children: [
              Container(width: 56, height: 56,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: C.surface,
                    border: Border.all(color: C.border, width: 0.5)),
                child: ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: img.isNotEmpty
                      ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover)
                      : const Icon(Icons.live_tv_rounded, color: C.dim, size: 24))),
              const SizedBox(height: 4),
              Text(item['name'] ?? '', style: T.cairo(s: 9, c: C.grey),
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ])));
      }));
}

// ── No Image Placeholder ───────────────────────────────────
class _NoImg extends StatelessWidget {
  final String name;
  const _NoImg(this.name);
  @override
  Widget build(BuildContext context) => Container(
    color: C.surface,
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.movie_rounded, color: C.dim, size: 22),
      const SizedBox(height: 4),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(name, style: T.cairo(s: 9, c: C.dim),
            maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
    ])));
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final top  = MediaQuery.of(context).padding.top;
    // Hero: أفضل القنوات (bein/sky) أو أول 8
    final hero = _filtered.where((c) {
      final n = (c['name'] ?? '').toString().toLowerCase();
      return n.contains('bein') || n.contains('sky') || n.contains('mbc');
    }).take(8).toList();
    final heroList = hero.isNotEmpty ? hero : _filtered.take(8).toList();

    return Scaffold(backgroundColor: C.bg,
      body: RefreshIndicator(color: C.gold, backgroundColor: C.surface,
        strokeWidth: 1.5, onRefresh: _refresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [

            // ── Hero Carousel للقنوات المميزة ──
            if (heroList.isNotEmpty)
              SliverToBoxAdapter(child: _LiveHeroCarousel(
                channels: heroList, onTap: _openChannel)),

            // ── Header + Search ──
            SliverToBoxAdapter(child: _AppHdr(
                top: heroList.isEmpty ? top : 0,
                title: 'مباشر', onRefresh: _refresh)),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(14,8,14,0),
              child: _SearchBar(ctrl: _ctrl,
                  onChanged: (v) => setState(() { _query = v; _apply(); })))),

            // ── أقسام ──
            if (AppState.liveCats.isNotEmpty)
              SliverToBoxAdapter(child: SizedBox(height: 46, child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

            // ── Grid القنوات ──
            SliverPadding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols(context),
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 10, mainAxisSpacing: 10),
                delegate: SliverChildBuilderDelegate(
                    (_, i) => _ContentCard(
                        item: _filtered[i], type: 'live',
                        onTap: () => _openChannel(_filtered[i]),
                        onFav: () => setState(() {})),
                    childCount: _filtered.length,
                    addRepaintBoundaries: true, addAutomaticKeepAlives: false))),
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
                  ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, memCacheHeight: 600,
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
    var b = _source;
    if (_selCat.isNotEmpty) b = b.where((e) => e['category_id']?.toString() == _selCat).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      b = b.where((e) => (e['name'] ?? '').toString().toLowerCase().contains(q)).toList();
    }
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
    if (_viewMode == 'grid') return 3;
    if (_viewMode == 'landscape') return 1;
    final w = MediaQuery.of(context).size.width;
    return w > 900 ? 5 : w > 600 ? 4 : 2;
  }

  double get _ratio {
    if (_viewMode == 'landscape') return 2.8;
    if (_viewMode == 'grid') return 0.65;
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

  Widget _buildPortrait(String img, String name) =>
    RepaintBoundary(child: GestureDetector(onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8),
          child: Stack(fit: StackFit.expand, children: [
            img.isNotEmpty
                ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover,
                    memCacheHeight: 320, fadeInDuration: const Duration(milliseconds: 150),
                    placeholder: (_, __) => Container(color: C.surface),
                    errorWidget: (_, __, ___) => _NoImg(name))
                : _NoImg(name),
            // Bookmark
            Positioned(top: 4, right: 4, child: StatefulBuilder(builder: (_, ss) {
              final fav = WL.has(item);
              return GestureDetector(
                onTap: () async { await WL.toggle(item, type); ss(() {}); onFav(); },
                child: Container(width: 28, height: 28,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.6)),
                  child: Icon(fav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: fav ? C.gold : C.white.withOpacity(0.7), size: 14)));
            })),
            if (type == 'live')
              Positioned(bottom: 6, left: 6,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: C.live, borderRadius: BorderRadius.circular(3)),
                  child: Text('LIVE', style: T.mont(s: 7, c: Colors.white, w: FontWeight.w800)))),
          ]))),
        const SizedBox(height: 5),
        Text(name, style: T.cairo(s: 10, c: C.white.withOpacity(0.9)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ])));

  Widget _buildLandscape(String img, String name) =>
    RepaintBoundary(child: GestureDetector(onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: C.border, width: 0.4)),
        child: Row(children: [
          ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            child: SizedBox(width: 80, height: double.infinity,
              child: img.isNotEmpty
                  ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, memCacheHeight: 200)
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
      _tc = TabController(length: seas.isNotEmpty ? seas.length : 1, vsync: this);
      if (seas.isNotEmpty) {
        _tc!.addListener(() {
          if (!_tc!.indexIsChanging) return;
          if (_tc!.index < seas.length) setState(() => _season = seas[_tc!.index]);
        });
      }
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
    Navigator.push(context, _fade(PlayerPage(urls: urls, title: title)));
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
                  ? CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover,
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
                      child: CachedNetworkImage(imageUrl: poster, fit: BoxFit.cover,
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
        body: eps.isEmpty
            ? Center(child: Text('لا توجد حلقات', style: T.mont(s: 13, c: C.grey)))
            : ListView.builder(
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
                                  ? CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover,
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
                })));
  }
}

// ══════════════════════════════════════════════════════════════
//  SPORTS PAGE — تصميم TOD للرياضة
// ══════════════════════════════════════════════════════════════
class SportsPage extends StatefulWidget {
  const SportsPage();
  @override State<SportsPage> createState() => _SportsPageState();
}

class _SportsPageState extends State<SportsPage> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  bool _busy    = true;
  String _status= '';
  int _heroCur  = 0;

  static const _sportsKw = [
    'bein','beinsport','sport','sports','sky sport','sky sports',
    'رياضة','رياضي','كورة','football','soccer','eurosport',
    'arena','dazn','مباشر','laliga','bundesliga','serie a',
    'champions','premier league','match tv',
  ];

  static const _catDefs = [
    {'key': 'bein',      'label': 'beIN Sports', 'color': 0xFF00A651},
    {'key': 'sky',       'label': 'Sky Sports',  'color': 0xFF1D4ED8},
    {'key': 'eurosport', 'label': 'Eurosport',   'color': 0xFFD97706},
    {'key': 'arena',     'label': 'Arena',        'color': 0xFF0369A1},
    {'key': 'sport',     'label': 'رياضة',        'color': 0xFFDC2626},
    {'key': 'كورة',      'label': 'كورة',          'color': 0xFF059669},
  ];

  List<dynamic> _channels = [];
  List<dynamic> get _heroCh {
    final prio = _channels.where((c) {
      final n = (c['name']??'').toString().toLowerCase();
      return n.contains('bein') || n.contains('بين') || n.contains('sky');
    }).take(10).toList();
    return prio.isNotEmpty ? prio : _channels.take(8).toList();
  }

  List<dynamic> _catCh(String key) {
    // VIP: عرض جميع القنوات بما فيها المقفلة
    final all = _channels.where((c) {
      final n = "\${c['name']??''} \${c['category_name']??''}".toLowerCase();
      return n.contains(key.toLowerCase());
    }).toList();
    // مجاني: 4 قنوات رياضية فقط
    if (Sub.isFree) return all.take(4).toList();
    // عادي: beIN 1-8 + Sky + Eurosport
    if (Sub.isNormal) return all.take(15).toList();
    // VIP: كل شيء
    return all;
  }

  @override void initState() { super.initState(); _load(); }

  Future<void> _load({bool force = false}) async {
    if (mounted) setState(() { _busy = true; _status = 'جاري التحميل...'; });

    // من AppState أولاً
    if (AppState.allLive.isNotEmpty && !force) {
      _filterChannels(AppState.allLive);
      if (_channels.isNotEmpty) {
        if (mounted) setState(() { _busy = false; _status = ''; });
        _refreshBg();
        return;
      }
    }

    // جلب مباشر
    if (mounted) setState(() => _status = 'جلب القنوات...');
    try {
      final live = await Api.getList('get_live_streams', force: force);
      if (live.isNotEmpty) {
        AppState.allLive = live;
        _filterChannels(live);
      }
    } catch (_) {}

    // جلب حسب الأقسام
    if (_channels.isEmpty) {
      if (mounted) setState(() => _status = 'البحث في الأقسام الرياضية...');
      try {
        final cats = await Api.getList('get_live_categories');
        final sportsCats = cats.where((cat) {
          final name = (cat['category_name'] ?? '').toString().toLowerCase();
          return _sportsKw.any((k) => name.contains(k));
        }).toList();
        final channels = <dynamic>[];
        for (final cat in sportsCats.take(8)) {
          final id = cat['category_id']?.toString() ?? '';
          if (id.isEmpty) continue;
          final chs = await Api.getList('get_live_streams', extra: {'category_id': id});
          channels.addAll(chs);
        }
        if (channels.isNotEmpty) _filterChannels(channels);
      } catch (_) {}
    }

    if (mounted) setState(() { _busy = false; _status = ''; _channels = _channels; });
  }

  void _filterChannels(List<dynamic> all) {
    final filtered = all.where((ch) {
      final n = '${ch['name']??''} ${ch['category_name']??''}'.toLowerCase();
      return _sportsKw.any((k) => n.contains(k));
    }).toList();

    // ترتيب ذكي حسب اسم القناة
    filtered.sort((a, b) {
      final na = (a['name'] ?? '').toString().toLowerCase();
      final nb = (b['name'] ?? '').toString().toLowerCase();
      int scoreA = _chScore(na);
      int scoreB = _chScore(nb);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      // داخل نفس المجموعة: ترتيب رقمي
      final numA = _extractNum(na);
      final numB = _extractNum(nb);
      if (numA != null && numB != null) return numA.compareTo(numB);
      return na.compareTo(nb);
    });

    _channels = filtered.isNotEmpty ? filtered : all.take(50).toList();
  }

  // أولوية القنوات الرياضية
  int _chScore(String n) {
    if (n.contains('bein') && n.contains('4k')) return 95;
    if (n.contains('bein') || n.contains('بين')) return 100;
    if (n.contains('sky sport')) return 90;
    if (n.contains('eurosport')) return 85;
    if (n.contains('arena')) return 80;
    if (n.contains('dazn')) return 75;
    if (n.contains('champions') || n.contains('uefa')) return 70;
    if (n.contains('كورة') || n.contains('football')) return 65;
    if (n.contains('sport') || n.contains('رياض')) return 60;
    return 50;
  }

  // استخراج الرقم من اسم القناة (beIN Sports 3 → 3)
  int? _extractNum(String name) {
    final m = RegExp(r'\d+').firstMatch(name);
    return m != null ? int.tryParse(m.group(0)!) : null;
  }

  Future<void> _refreshBg() async {
    try {
      final live = await Api.getList('get_live_streams', force: true);
      if (live.isNotEmpty && mounted) {
        AppState.allLive = live;
        _filterChannels(live);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  void _play(dynamic ch) {
    Sound.hapticL();
    Navigator.push(context, _fade(PlayerPage(
        urls: Api.liveUrls(ch), title: ch['name']?.toString() ?? '', isLive: true)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final top = MediaQuery.of(context).padding.top;

    if (_busy && _channels.isEmpty) return Scaffold(backgroundColor: C.bg, body: Column(children: [
      _hdr(top), Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _Pulse(label: 'الرياضة'), const SizedBox(height: 12),
        Text(_status, style: T.cairo(s: 12, c: C.grey)),
      ])))]));

    if (_channels.isEmpty) return Scaffold(backgroundColor: C.bg, body: Column(children: [
      _hdr(top), Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 70, height: 70,
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.sports_soccer_rounded, color: C.dim, size: 36)),
        const SizedBox(height: 18),
        Text('لا توجد قنوات رياضية', style: T.cairo(s: 15, w: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('تحقق من الاتصال', style: T.cairo(s: 12, c: C.grey)),
        const SizedBox(height: 24),
        GestureDetector(onTap: () => _load(force: true),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(gradient: C.playGrad, borderRadius: BorderRadius.circular(12)),
            child: Text('إعادة المحاولة', style: T.cairo(s: 13, w: FontWeight.w800, c: Colors.black)))),
      ])))]));

    return Scaffold(backgroundColor: C.bg,
      body: RefreshIndicator(color: C.gold, backgroundColor: C.surface, strokeWidth: 1.5,
        onRefresh: () => _load(force: true),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _hdr(top)),
            if (_heroCh.isNotEmpty)
              SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _secHdr('القنوات الرياضية', _channels.length)),
            SliverToBoxAdapter(child: _grid2col(_channels)),
            for (final cat in _catDefs) ...() {
              final list = _catCh(cat['key'] as String);
              if (list.isEmpty) return <Widget>[];
              return [
                SliverToBoxAdapter(child: _secHdr(cat['label'] as String, list.length,
                    color: Color(cat['color'] as int))),
                SliverToBoxAdapter(child: _hRow(list)),
              ];
            }(),
            if (_busy) const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(backgroundColor: Colors.transparent,
                  color: C.gold, minHeight: 1.5))),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ])));
  }

  Widget _hdr(double top) => Container(
    height: 52 + top, padding: EdgeInsets.only(top: top, left: 16, right: 16), color: C.bg,
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(color: C.goldBg, borderRadius: BorderRadius.circular(9)),
        child: const Icon(Icons.sports_soccer_rounded, color: C.gold, size: 18)),
      const SizedBox(width: 10),
      Text('رياضة', style: T.cairo(s: 18, w: FontWeight.w800)),
      const SizedBox(width: 8),
      if (_channels.isNotEmpty)
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: C.goldBg, borderRadius: BorderRadius.circular(8)),
          child: Text('${_channels.length}', style: T.mont(s: 10, c: C.gold, w: FontWeight.w700))),
      const Spacer(),
      if (_busy) const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(color: C.gold, strokeWidth: 1.5)),
      const SizedBox(width: 8),
      GestureDetector(onTap: () => _load(force: true),
        child: Container(width: 34, height: 34,
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.border, width: 0.5)),
          child: const Icon(Icons.refresh_rounded, color: C.grey, size: 17))),
    ]));

  Widget _buildHero() {
    final h = MediaQuery.of(context).size.height * 0.40;
    final list = _heroCh;
    return SizedBox(height: h, child: Stack(children: [
      _AutoPageView(
        itemCount: list.length,
        interval: const Duration(seconds: 4),
        onPageChanged: (i) => setState(() => _heroCur = i),
        itemBuilder: (_, i) {
          final ch  = list[i];
          final img = ch['stream_icon']?.toString() ?? '';
          final nm  = ch['name']?.toString() ?? '';
          return GestureDetector(onTap: () => _play(ch),
            child: Stack(fit: StackFit.expand, children: [
              img.isNotEmpty
                  ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, memCacheHeight: 600,
                      placeholder: (_, __) => _sportsBg(nm),
                      errorWidget: (_, __, ___) => _sportsBg(nm))
                  : _sportsBg(nm),
              DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  stops: const [0.3, 1.0],
                  colors: [Colors.transparent, Colors.black.withOpacity(0.92)]))),
              Positioned(bottom: 52, left: 16, right: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: C.live, borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 5, height: 5, margin: const EdgeInsets.only(left: 4),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                      Text('مباشر', style: T.mont(s: 9, c: Colors.white, w: FontWeight.w800)),
                    ])),
                  const SizedBox(height: 8),
                  Text(nm, style: T.cairo(s: 20, w: FontWeight.w900), maxLines: 1,
                      overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    GestureDetector(onTap: () => _play(ch),
                      child: Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(gradient: C.playGrad,
                            borderRadius: BorderRadius.circular(22)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                          const SizedBox(width: 4),
                          Text('مشاهدة', style: T.cairo(s: 13, c: Colors.black, w: FontWeight.w800)),
                        ]))),
                  ]),
                ])),
            ]));
        }),
      Positioned(bottom: 16, left: 0, right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(list.length > 8 ? 8 : list.length, (i) =>
            AnimatedContainer(duration: const Duration(milliseconds: 200),
              width: i == _heroCur ? 20 : 5, height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i == _heroCur ? C.gold : C.dim,
                borderRadius: BorderRadius.circular(2)))))),
    ]));
  }

  Widget _sportsBg(String name) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [Color(0xFF0A1628), Color(0xFF1A2840)],
        begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.sports_soccer_rounded, color: C.gold.withOpacity(0.45), size: 30),
      const SizedBox(height: 6),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(name, style: T.cairo(s: 13, c: C.white.withOpacity(0.8)),
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
    ])));

  Widget _secHdr(String label, int count, {Color color = C.gold}) =>
    Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(children: [
        Container(width: 4, height: 18,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(label, style: T.cairo(s: 15, w: FontWeight.w700)),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Text('$count', style: T.mont(s: 11, c: color, w: FontWeight.w700))),
      ]));

  Widget _grid2col(List<dynamic> list) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 1.55, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: list.length > 60 ? 60 : list.length,
      itemBuilder: (_, i) {
        final ch  = list[i];
        final img = ch['stream_icon']?.toString() ?? '';
        final nm  = ch['name']?.toString() ?? '';
        return GestureDetector(onTap: () => _play(ch),
          child: Container(decoration: BoxDecoration(color: C.card,
              borderRadius: BorderRadius.circular(10), border: Border.all(color: C.border, width: 0.4)),
            child: Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10),
                child: img.isNotEmpty
                    ? CachedNetworkImage(imageUrl: img, width: double.infinity,
                        height: double.infinity, fit: BoxFit.cover, memCacheHeight: 200,
                        placeholder: (_, __) => Container(color: C.surface),
                        errorWidget: (_, __, ___) => _sportsBg(nm))
                    : _sportsBg(nm)),
              ClipRRect(borderRadius: BorderRadius.circular(10),
                child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.75)])))),
              Positioned(top: 6, left: 6,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: C.live, borderRadius: BorderRadius.circular(4)),
                  child: Text('LIVE', style: T.mont(s: 7, c: Colors.white, w: FontWeight.w800)))),
              Positioned(top: 4, right: 4,
                child: Container(width: 26, height: 26,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                      border: Border.all(color: C.gold.withOpacity(0.6), width: 0.8)),
                  child: const Icon(Icons.play_arrow_rounded, color: C.gold, size: 14))),
              Positioned(bottom: 6, left: 6, right: 6,
                child: Text(nm, style: T.cairo(s: 9, w: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
            ])));
      }));

  Widget _hRow(List<dynamic> list) => SizedBox(height: 124,
    child: ListView.builder(scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: list.length > 20 ? 20 : list.length,
      itemBuilder: (_, i) {
        final ch  = list[i];
        final img = ch['stream_icon']?.toString() ?? '';
        final nm  = ch['name']?.toString() ?? '';
        return GestureDetector(onTap: () => _play(ch),
          child: Container(width: 175, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: C.border, width: 0.5)),
            child: Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10),
                child: img.isNotEmpty
                    ? CachedNetworkImage(imageUrl: img, width: double.infinity,
                        height: double.infinity, fit: BoxFit.cover, memCacheHeight: 200,
                        errorWidget: (_, __, ___) => _sportsBg(nm))
                    : _sportsBg(nm)),
              ClipRRect(borderRadius: BorderRadius.circular(10),
                child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)])))),
              Positioned(top: 5, left: 5,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: C.live, borderRadius: BorderRadius.circular(3)),
                  child: Text('LIVE', style: T.mont(s: 7, c: Colors.white, w: FontWeight.w800)))),
              Positioned(bottom: 6, left: 6, right: 6,
                child: Text(nm, style: T.cairo(s: 9, w: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
            ])));
      }));
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
  bool _busy         = false;
  String _err        = '';
  bool _showVip      = false;
  bool _showCode     = false;
  bool _passVisible  = false;

  @override void dispose() {
    _codeCtrl.dispose(); _userCtrl.dispose(); _passCtrl.dispose();
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
      _toast(res.msg);
      FirebaseAnalytics.instance.logEvent(name: 'vip_login');
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
      _toast(res.msg);
      FirebaseAnalytics.instance.logEvent(name: 'code_activated',
          parameters: {'plan': res.plan});
    }
  }

  Future<void> _doLogout() async {
    await Sub.logout();
    if (mounted) setState(() {});
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
          expandedHeight: 120,
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

  // ── VIP Form ─────────────────────────────────────────────────
  Widget _buildVipForm() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF120D00), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: C.gold.withOpacity(0.35)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.workspace_premium_rounded, color: C.gold, size: 18),
        SizedBox(width: 8),
        Text('تسجيل دخول VIP', style: TextStyle(color: C.gold, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
      const SizedBox(height: 14),
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
          onPressed: _busy ? null : _doVipLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: C.gold, foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            disabledBackgroundColor: C.gold.withOpacity(0.4),
          ),
          child: _busy
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('دخول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
  Widget _buildLogoutBtn() => TextButton.icon(
    onPressed: _doLogout,
    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
    label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
  );
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


class PlayerPage extends StatefulWidget {
  final List<String> urls; final String title; final bool isLive;
  const PlayerPage({required this.urls, required this.title, this.isLive = false});
  @override State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with TickerProviderStateMixin {
  VideoPlayerController? _vc;
  VideoPlayerController? _introVc;   // مقدمة الفيلم
  bool _showingIntro = false;         // هل نعرض المقدمة الآن؟
  late final AnimationController _ov, _sp, _wm;
  late final Animation<double>   _ovAn, _wmAn;

  bool _inited = false, _err = false, _buf = true;
  bool _overlay = true, _fs = true, _muted = false;
  double _vol = 1.0, _brightness = 0.5;
  bool _seekDrag = false; double _seekVal = 0;
  bool _volDrag = false, _brightDrag = false;
  double _gestY = 0;
  String _errMsg = '';
  int _urlIdx = 0;
  static const _maxR = 3;
  Timer? _hideT;

  @override
  void initState() {
    super.initState();
    _ov = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _sp = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _wm = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _ovAn = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ov, curve: Curves.easeOut));
    _wmAn = Tween<double>(begin: 0.06, end: 0.14).animate(CurvedAnimation(parent: _wm, curve: Curves.easeInOut));

    if (!kIsWeb) WakelockPlus.enable();
    _enterFs();
    // ── منع التسجيل فقط داخل المشغل ──
    SecurityLayer.enableScreenRecord();
    _ov.forward(); _schedHide();
    // للأفلام والمسلسلات فقط: تشغيل مقدمة أولاً
    if (!widget.isLive) {
      _playIntro();
    } else {
      _init(widget.urls.first);
    }
  }


  // ── مقدمة الفيلم/المسلسل ─────────────────────────────────
  Future<void> _playIntro() async {
    if (!mounted) return;
    setState(() { _showingIntro = true; _buf = true; _err = false; });
    try {
      final vc = VideoPlayerController.asset('assets/videos/intro.mp4',
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false));
      await vc.initialize();
      await vc.setVolume(1.0);
      // لا full screen — الفيديو يعمل داخل المشغل الطبيعي
      _introVc = vc;
      if (mounted) setState(() { _buf = false; });
      await vc.play();
      // انتظر انتهاء المقدمة
      vc.addListener(() {
        if (!vc.value.isPlaying && vc.value.position >= vc.value.duration &&
            _showingIntro && mounted) {
          _onIntroEnd();
        }
      });
    } catch (_) {
      // إذا فشل تحميل المقدمة → ابدأ المحتوى مباشرة
      _onIntroEnd();
    }
  }

  void _onIntroEnd() {
    if (!mounted) return;
    _introVc?.dispose();
    _introVc = null;
    setState(() { _showingIntro = false; _buf = true; });
    // ابدأ المحتوى الرئيسي
    _init(widget.urls.first);
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
      await vc.play();
      if (mounted) { final old = _vc; setState(() { _vc = vc; _inited = true; _buf = false; }); old?.dispose(); }
      else { vc.dispose(); }
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

  void _tryNext(String r) {
    _urlIdx++;
    if (_urlIdx < widget.urls.length && _urlIdx < _maxR) { _init(widget.urls[_urlIdx]); return; }
    String msg;
    if (r.toLowerCase().contains('timeout')) msg = 'انتهت مهلة الاتصال';
    else if (r.contains('404')) msg = 'المحتوى غير موجود';
    else if (r.contains('403')) msg = 'انتهت صلاحية الرابط';
    else msg = 'تعذّر تشغيل المحتوى';
    if (mounted) setState(() { _err = true; _buf = false; _errMsg = msg; });
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
    _hideT?.cancel(); _vc?.dispose(); _ov.dispose(); _sp.dispose(); _wm.dispose();
    if (!kIsWeb) WakelockPlus.disable();
    // ── إلغاء منع التسجيل عند الخروج ──
    SecurityLayer.disableScreenRecord();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    Scaffold(backgroundColor: Colors.black, body: _err ? _buildErr() : _buildPlayer());

  Widget _buildErr() => Container(color: Colors.black, child: SafeArea(child: Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 68, height: 68, decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: C.dim), color: C.surface),
          child: const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
              color: C.dim, size: 28)),
      const SizedBox(height: 18),
      Text('تعذّر التشغيل', style: T.cairo(s: 16, w: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(_errMsg, style: T.mont(s: 12, c: C.grey), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      GestureDetector(onTap: () { setState(() { _err = false; _buf = true; _urlIdx = 0; });
          _init(widget.urls.first); },
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(gradient: C.playGrad, borderRadius: BorderRadius.circular(12)),
          child: Text('إعادة المحاولة', style: T.cairo(s: 13, c: Colors.black, w: FontWeight.w800)))),
      const SizedBox(height: 10),
      GestureDetector(onTap: () => Navigator.pop(context),
        child: Text('رجوع', style: T.mont(s: 12, c: C.dim))),
    ]))));

  Widget _buildPlayer() {
    final vc = _vc;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleOv,
      onDoubleTapDown: (d) => _seekBy(d.globalPosition.dx < context.size!.width / 2 ? -10 : 10),
      onVerticalDragStart: (d) {
        _gestY    = d.localPosition.dy;
        _volDrag   = d.localPosition.dx > context.size!.width * 0.6;
        _brightDrag= d.localPosition.dx < context.size!.width * 0.4;
      },
      onVerticalDragUpdate: (d) {
        if (!_volDrag && !_brightDrag) return;
        final delta = (_gestY - d.localPosition.dy) / (context.size!.height * 0.6);
        if (_volDrag) { _vol = (_vol + delta).clamp(0.0, 1.0); _vc?.setVolume(_vol); }
        else          { _brightness = (_brightness + delta).clamp(0.0, 1.0); }
        _gestY = d.localPosition.dy; setState(() {});
      },
      onVerticalDragEnd: (_) { _volDrag = false; _brightDrag = false; },
      child: Stack(fit: StackFit.expand, children: [
        // ── Intro clip (movies/series only) ────────────────
        if (_showingIntro && _introVc != null && _introVc!.value.isInitialized)
          Positioned.fill(child: FittedBox(
            fit: BoxFit.contain,   // طبيعي بدون full-screen تمدد
            child: SizedBox(
              width:  _introVc!.value.size.width  > 0 ? _introVc!.value.size.width  : 1920,
              height: _introVc!.value.size.height > 0 ? _introVc!.value.size.height : 1080,
              child:  VideoPlayer(_introVc!)))),
        // ── Main content ─────────────────────────────────────
        if (!_showingIntro)
          (_inited && vc != null)
            ? Positioned.fill(child: FittedBox(fit: BoxFit.cover,
                child: SizedBox(
                  width:  vc.value.size.width  > 0 ? vc.value.size.width  : 1920,
                  height: vc.value.size.height > 0 ? vc.value.size.height : 1080,
                  child:  VideoPlayer(vc))))
            : Container(color: Colors.black),
        // Watermark
        Positioned(bottom: 70, right: 16, child: AnimatedBuilder(animation: _wmAn,
          builder: (_, __) => Opacity(opacity: _wmAn.value,
            child: Text('TOTV+', style: T.cinzel(s: 10, c: Colors.white).copyWith(letterSpacing: 2.5))))),
        // Gesture indicator
        if (_volDrag || _brightDrag) _buildGestureInd(),
        // Spinner
        if (_buf && !_err) Center(child: AnimatedBuilder(animation: _sp,
          builder: (_, __) => Transform.rotate(angle: _sp.value * 6.28,
            child: Container(width: 50, height: 50,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: C.gold.withOpacity(0.12), width: 1.5)),
              child: SizedBox(width: 34, height: 34,
                child: CircularProgressIndicator(color: C.gold.withOpacity(0.65),
                    strokeWidth: 1.5)))))),
        FadeTransition(opacity: _ovAn, child: _overlay ? _buildOverlay(vc) : const SizedBox.shrink()),
      ]));
  }

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
    return Container(padding: EdgeInsets.only(top: top + 8, left: 16, right: 16, bottom: 8),
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
        GestureDetector(onTap: _fs ? _exitFs : _enterFs,
          child: Container(width: 34, height: 34,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(_fs ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                color: C.white, size: 20))),
      ]));
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
            onHorizontalDragStart: (_) => setState(() { _seekDrag = true; _seekVal = _prog; }),
            onHorizontalDragUpdate: (d) {
              final b = context.findRenderObject() as RenderBox?; if (b == null) return;
              setState(() => _seekVal = (d.localPosition.dx / b.size.width).clamp(0.0, 1.0));
            },
            onHorizontalDragEnd: (_) { vc?.seekTo(dur * _seekVal); setState(() => _seekDrag = false); },
            child: SizedBox(height: 22, child: Stack(alignment: Alignment.centerLeft, children: [
              Container(height: 3, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2))),
              FractionallySizedBox(widthFactor: _bufd, child: Container(height: 3,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(2)))),
              FractionallySizedBox(widthFactor: _seekDrag ? _seekVal : _prog,
                child: Container(height: 3, decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [C.goldLight, C.gold]),
                    borderRadius: BorderRadius.circular(2)))),
              FractionallySizedBox(widthFactor: _seekDrag ? _seekVal : _prog,
                child: Align(alignment: Alignment.centerRight,
                  child: Container(width: _seekDrag ? 14 : 10, height: _seekDrag ? 14 : 10,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: C.gold,
                        boxShadow: [BoxShadow(color: C.gold.withOpacity(0.5), blurRadius: 5)])))),
            ]))),
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
          SizedBox(width: 90, child: Row(children: [
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
  transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
  transitionDuration: const Duration(milliseconds: 280));


// ═══════════════════════════════════════════ END TOTV+ v12.0 ═══════════════════════════════════

