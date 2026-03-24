// ═══════════════════════════════════════════════════════════════
//  TOTV+ CMS Worker v1.0 — النظام المتكامل
//
//  ✅ /assign-server    — يعطي كل مستخدم سيرفر حسب باقته (24h cache)
//  ✅ /content          — قائمة الأفلام+بوسترات+وصف من KV (كل 5 ساعات)
//  ✅ /live-config      — إعدادات البث المباشر (يُحدَّث فوراً)
//  ✅ /app-config       — إعدادات التطبيق (maintenance, version...)
//  ✅ /refresh-url      — تحديث رابط منكسر من السيرفر الأصلي
//  ✅ /vodu-search      — بحث تلقائي في vodu.me
//  ✅ /img              — proxy للصور (http→https)
//  ✅ /admin/*          — Admin API كامل (محمي بـ Token)
//  ✅ /health           — فحص حالة النظام
//  ✅ /version          — معلومات الإصدار
//
//  KV Namespaces المطلوبة (في wrangler.toml):
//    [[kv_namespaces]]
//    binding = "KV"
//    id = "YOUR_KV_ID"
//
//  Environment Variables:
//    ADMIN_TOKEN       — توكن الأدمن
//    FCM_SERVER_KEY    — Firebase Server Key
//    ENCRYPT_KEY       — مفتاح التشفير (16 حرف)
// ═══════════════════════════════════════════════════════════════

// ── KV Keys ──────────────────────────────────────────────────
const KV_SERVERS    = 'cms:servers';        // قائمة السيرفرات
const KV_GROUPS     = 'cms:groups';         // الأفرع
const KV_SETTINGS   = 'cms:settings';       // إعدادات التطبيق
const KV_SECTIONS   = 'cms:sections:';      // prefix + plan
const KV_SUBS       = 'cms:subs:';          // prefix + device_id
const KV_SUBS_IDX   = 'cms:subs_index';     // فهرس الاشتراكات
const KV_CODES      = 'cms:codes:';         // prefix + code
const KV_CODES_IDX  = 'cms:codes_index';    // فهرس الأكواد
const KV_NOTIFS     = 'cms:notifs';         // الإشعارات النشطة
const KV_BLOCKED    = 'cms:blocked';        // القنوات المحجوبة
const KV_CONTENT    = 'cms:content';        // كاش المحتوى
const KV_CONTENT_TS = 'cms:content_ts';     // وقت آخر تحديث
const KV_OPENS      = 'cms:opens:';         // prefix + date (إحصاءات)
const KV_ONLINE     = 'cms:online:';        // prefix + device_id

// ── TTL ──────────────────────────────────────────────────────
const TTL_CONTENT   = 5 * 3600;      // 5 ساعات للمحتوى في KV
const TTL_ONLINE    = 120;           // 2 دقيقة للمستخدمين المتصلين

// ── Default Settings ─────────────────────────────────────────
const DEFAULT_SETTINGS = {
  maintenance: false,   maint_msg: 'نعمل على تحسين الخدمة',
  locked: false,        lock_msg:  'التطبيق متوقف مؤقتاً',
  force_update: false,  min_version: 18,
  update_url: 'https://hamza123123123.github.io/totv/#',
  guest_limit: 200,     buy_url: 'https://t.me/O_2828',
  vip_buy_url: '',      support_whatsapp: '9647714415816',
  support_telegram: 'https://t.me/O_2828',
  sub_btn_text: 'اشترك لمشاهدة هذا المحتوى',
  sub_btn_url: '',
};

// ════════════════════════════════════════════════════════════════
//  ENTRY POINT
// ════════════════════════════════════════════════════════════════
export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') return preflight();
    const url  = new URL(request.url);
    const path = url.pathname;

    // ── Public endpoints ──────────────────────────────────────
    if (path === '/health')                return handleHealth(env);
    if (path === '/version')               return handleVersion(env);
    if (path === '/assign-server')         return handleAssignServer(request, url, env);
    if (path === '/app-config')            return handleAppConfig(env);
    if (path === '/live-config')           return handleLiveConfig(env);
    if (path === '/content')               return handleContent(request, url, env, ctx);
    if (path === '/refresh-url')           return handleRefreshUrl(url, env);
    if (path === '/vodu-search')           return handleVoduSearch(url, env);
    if (path.startsWith('/img'))           return handleImgProxy(url);
    if (path.startsWith('/stream/'))       return handleStream(request, url, env);
    if (path.startsWith('/hls/'))          return handleHls(url, env);
    if (path.startsWith('/vip-stream'))    return handleVipStream(request, url);

    // ── Admin endpoints (محمية) ───────────────────────────────
    if (path.startsWith('/admin/')) {
      if (!checkAdminToken(request, env)) return jsonResp({ error: 'unauthorized' }, 401);
      return handleAdmin(path.replace('/admin/', ''), request, url, env, ctx);
    }

    // ── Legacy API proxy ─────────────────────────────────────
    if (url.searchParams.has('action')) return handleApiProxy(request, url, env);

    return jsonResp({ status: 'TOTV+ CMS v1.0', ts: Date.now() });
  }
};

// ════════════════════════════════════════════════════════════════
//  ASSIGN SERVER — يعطي كل مستخدم سيرفر حسب باقته
//  POST /assign-server  { plan, device_id, group_id? }
//  Response: { host, username, password, plan, expires_at, cached_hours:24 }
// ════════════════════════════════════════════════════════════════
async function handleAssignServer(request, url, env) {
  let body = {};
  try { body = await request.json(); } catch (_) {}

  const plan     = body.plan     || url.searchParams.get('plan')      || 'free';
  const deviceId = body.device_id|| url.searchParams.get('device_id') || '';
  const groupId  = body.group_id || url.searchParams.get('group_id')  || '';

  // تسجيل النشاط
  if (deviceId) {
    trackOpen(env, deviceId, plan);
    trackOnline(env, deviceId, plan);
  }

  // 1. فحص الاشتراك من KV (للتحقق من انتهاء الصلاحية)
  let activePlan = plan;
  if (deviceId) {
    const sub = await getKV(env, KV_SUBS + deviceId);
    if (sub) {
      if (sub.expiry < Date.now()) {
        // انتهى الاشتراك — رجوع للمجاني
        activePlan = 'free';
        await setKV(env, KV_SUBS + deviceId, { ...sub, plan: 'free' });
      } else {
        activePlan = sub.plan;
      }
    }
  }

  // 2. إذا كان لديه group_id — ابحث في الأفرع أولاً
  if (groupId) {
    const groups = await getKV(env, KV_GROUPS) || [];
    const grp = groups.find(g => g.id === groupId);
    if (grp && grp.server_id) {
      const srv = await findServer(env, grp.server_id);
      if (srv) return jsonResp(buildServerResp(srv, activePlan));
    }
  }

  // 3. اختر السيرفر المناسب للباقة
  const servers = await getKV(env, KV_SERVERS) || [];
  const active  = servers.filter(s => s.active !== false);

  // ترتيب: VIP → normal → free
  const planMap = { vip: ['vip', 'normal', 'free'], normal: ['normal', 'free'], basic: ['normal', 'free'], free: ['free', 'normal'] };
  const priority = planMap[activePlan] || ['free'];

  let chosen = null;
  for (const t of priority) {
    const candidates = active.filter(s => s.type === t).sort((a, b) => (a.priority||99) - (b.priority||99));
    if (candidates.length) { chosen = candidates[0]; break; }
  }

  // 4. Fallback: أي سيرفر متاح
  if (!chosen && active.length) chosen = active[0];

  // 5. Fallback نهائي: الإعدادات الافتراضية
  if (!chosen) {
    const settings = await getKV(env, KV_SETTINGS) || DEFAULT_SETTINGS;
    const fallback = settings.default_server;
    if (fallback) {
      chosen = { host: fallback.host, username: fallback.username, password: fallback.password, type: 'free' };
    }
  }

  if (!chosen) return jsonResp({ error: 'no_server_available', plan: activePlan }, 503);

  return jsonResp(buildServerResp(chosen, activePlan));
}

function buildServerResp(srv, plan) {
  // تحويل http → https للسيرفرات عبر proxy
  const host = srv.host || '';
  return {
    host:       host,
    https_host: toHttpsProxy(host),
    username:   srv.username || '',
    password:   srv.password || '',
    plan,
    cached_hours: 24,
    server_id: srv.id || '',
    ts: Date.now(),
  };
}

async function findServer(env, serverId) {
  const servers = await getKV(env, KV_SERVERS) || [];
  return servers.find(s => s.id === serverId && s.active !== false);
}

// ════════════════════════════════════════════════════════════════
//  APP CONFIG — إعدادات التطبيق (maintenance, version, etc.)
//  GET /app-config
// ════════════════════════════════════════════════════════════════
async function handleAppConfig(env) {
  const settings  = await getKV(env, KV_SETTINGS) || {};
  const merged    = { ...DEFAULT_SETTINGS, ...settings };
  const notifs    = await getKV(env, KV_NOTIFS) || [];
  const now       = Date.now();
  const active_notifs = notifs.filter(n => n.active && (!n.expiry || n.expiry > now));

  return jsonResp({
    maintenance:    merged.maintenance || false,
    maint_msg:      merged.maint_msg   || DEFAULT_SETTINGS.maint_msg,
    locked:         merged.locked      || false,
    lock_msg:       merged.lock_msg    || DEFAULT_SETTINGS.lock_msg,
    force_update:   merged.force_update|| false,
    min_version:    merged.min_version || DEFAULT_SETTINGS.min_version,
    update_url:     merged.update_url  || DEFAULT_SETTINGS.update_url,
    guest_limit:    merged.guest_limit || DEFAULT_SETTINGS.guest_limit,
    buy_url:        merged.buy_url     || DEFAULT_SETTINGS.buy_url,
    vip_buy_url:    merged.vip_buy_url || merged.buy_url || DEFAULT_SETTINGS.buy_url,
    support_whatsapp: merged.support_whatsapp || DEFAULT_SETTINGS.support_whatsapp,
    support_telegram: merged.support_telegram || DEFAULT_SETTINGS.support_telegram,
    sub_btn_text:   merged.sub_btn_text || DEFAULT_SETTINGS.sub_btn_text,
    sub_btn_url:    merged.sub_btn_url  || '',
    active_notifications: active_notifs.slice(0, 5),
    ts: Date.now(),
  });
}

// ════════════════════════════════════════════════════════════════
//  LIVE CONFIG — إعدادات البث المباشر
//  GET /live-config?plan=vip&device_id=xxx
// ════════════════════════════════════════════════════════════════
async function handleLiveConfig(env) {
  const servers  = await getKV(env, KV_SERVERS) || [];
  const blocked  = await getKV(env, KV_BLOCKED) || [];
  const active   = servers.filter(s => s.active !== false && s.type !== 'free');

  return jsonResp({
    servers: active.map(s => ({
      id: s.id, host: s.host,
      https_proxy: toHttpsProxy(s.host),
      username: s.username, password: s.password,
      type: s.type, priority: s.priority || 99,
    })),
    blocked_channels: blocked,
    ts: Date.now(),
  });
}

// ════════════════════════════════════════════════════════════════
//  CONTENT — قائمة المحتوى من KV (تتحدث كل 5 ساعات)
//  GET /content?type=movies|series|live&page=1&q=بحث
// ════════════════════════════════════════════════════════════════
async function handleContent(request, url, env, ctx) {
  const type  = url.searchParams.get('type') || 'movies';
  const page  = parseInt(url.searchParams.get('page') || '1');
  const query = url.searchParams.get('q') || '';
  const limit = 200;

  // جلب المحتوى من KV
  let content = await getKV(env, `${KV_CONTENT}:${type}`);
  const ts    = await env.KV.get(KV_CONTENT_TS + ':' + type);

  const needsRefresh = !content || !ts || (Date.now() - parseInt(ts || '0')) > TTL_CONTENT * 1000;

  if (needsRefresh) {
    // تحديث في الخلفية بدون تأخير الرد
    ctx.waitUntil(refreshContent(env, type));
    if (!content) {
      // لا يوجد كاش — جلب مباشر من السيرفر
      content = await fetchContentDirect(env, type);
    }
  }

  if (!content) return jsonResp({ items: [], total: 0, page, type });

  let items = content;

  // بحث
  if (query) {
    const q = query.toLowerCase();
    items = items.filter(i => {
      const name = (i.name || i.title || i.stream_name || '').toLowerCase();
      return name.includes(q);
    });
  }

  // Pagination
  const total  = items.length;
  const offset = (page - 1) * limit;
  const paged  = items.slice(offset, offset + limit);

  // تحويل جميع الصور لـ https
  const safe = paged.map(item => sanitizeItem(item));

  return jsonResp({ items: safe, total, page, pages: Math.ceil(total / limit), type, ts: ts ? parseInt(ts) : 0 });
}

// تحديث المحتوى من السيرفر في الخلفية
async function refreshContent(env, type) {
  try {
    const data = await fetchContentDirect(env, type);
    if (data && data.length > 0) {
      await setKV(env, `${KV_CONTENT}:${type}`, data, TTL_CONTENT + 3600);
      await env.KV.put(KV_CONTENT_TS + ':' + type, Date.now().toString(), { expirationTtl: TTL_CONTENT + 7200 });
    }
  } catch (_) {}
}

async function fetchContentDirect(env, type) {
  const settings = await getKV(env, KV_SETTINGS) || {};
  const servers  = await getKV(env, KV_SERVERS)  || [];

  // استخدم أول سيرفر متاح
  const srv = servers.find(s => s.active !== false) || null;
  const host = srv?.host || settings.default_server?.host || '';
  const user = srv?.username || settings.default_server?.username || '';
  const pass = srv?.password || settings.default_server?.password || '';

  if (!host || !user) return null;

  const actionMap = { movies: 'get_vod_streams', series: 'get_series', live: 'get_live_streams' };
  const action = actionMap[type] || 'get_vod_streams';

  const apiUrl = `${host.replace(/\/$/, '')}/player_api.php?username=${user}&password=${pass}&action=${action}`;

  try {
    const r = await fetch(apiUrl, { headers: { 'User-Agent': 'TOTV+CMS/1.0' }, signal: AbortSignal.timeout(20000) });
    if (!r.ok) return null;
    const data = await r.json();
    return Array.isArray(data) ? data : (data?.data || null);
  } catch (_) { return null; }
}

function sanitizeItem(item) {
  const keys = ['stream_icon', 'cover', 'backdrop_path', 'thumbnail', 'logo'];
  const out  = { ...item };
  for (const k of keys) {
    if (out[k] && typeof out[k] === 'string' && out[k].startsWith('http:')) {
      out[k] = '/img?url=' + encodeURIComponent(out[k]);
    }
  }
  return out;
}

// ════════════════════════════════════════════════════════════════
//  REFRESH URL — تحديث رابط تشغيل منكسر
//  GET /refresh-url?type=movie|series|live&id=12345&plan=vip
// ════════════════════════════════════════════════════════════════
async function handleRefreshUrl(url, env) {
  const type   = url.searchParams.get('type')   || 'movie';
  const id     = url.searchParams.get('id')     || '';
  const plan   = url.searchParams.get('plan')   || 'free';
  const ext    = url.searchParams.get('ext')    || 'mp4';
  const deviceId = url.searchParams.get('device_id') || '';

  if (!id) return jsonResp({ error: 'id_required' }, 400);

  // جلب بيانات السيرفر
  let serverData = null;
  if (deviceId) {
    const sub = await getKV(env, KV_SUBS + deviceId);
    if (sub && sub.expiry > Date.now()) serverData = sub.server;
  }

  if (!serverData) {
    // fallback: أول سيرفر متاح
    const servers = await getKV(env, KV_SERVERS) || [];
    const planType = plan === 'vip' ? 'vip' : (plan === 'normal' || plan === 'basic' ? 'normal' : 'free');
    const srv = servers.find(s => s.active !== false && s.type === planType) || servers.find(s => s.active !== false);
    if (srv) serverData = { host: srv.host, username: srv.username, password: srv.password };
  }

  if (!serverData) return jsonResp({ error: 'no_server' }, 503);

  const base   = serverData.host.replace(/\/$/, '');
  const user   = serverData.username;
  const pass   = serverData.password;

  const typeMap = { movie: 'movie', series: 'series', live: 'live' };
  const urlType = typeMap[type] || 'movie';

  const directUrl = `${base}/${urlType}/${user}/${pass}/${id}.${ext}`;
  const httpsUrl  = toHttpsProxy(directUrl);

  return jsonResp({
    url:       directUrl,
    https_url: httpsUrl,
    urls: [
      directUrl,
      `${base}/${urlType}/${user}/${pass}/${id}.mp4`,
    ],
    ts: Date.now(),
  });
}

// ════════════════════════════════════════════════════════════════
//  VODU SEARCH — بحث تلقائي في vodu.me
//  GET /vodu-search?title=اسم_الفيلم&type=movie|series&season=1&episode=1
// ════════════════════════════════════════════════════════════════
async function handleVoduSearch(url, env) {
  const title   = url.searchParams.get('title')   || '';
  const type    = url.searchParams.get('type')    || 'movie';
  const season  = url.searchParams.get('season')  || '';
  const episode = url.searchParams.get('episode') || '';

  if (!title) return jsonResp({ error: 'title_required' }, 400);

  try {
    // بحث في vodu.me
    const searchQuery = encodeURIComponent(title.trim());
    const searchUrl = `https://movie.vodu.me/search?q=${searchQuery}`;

    const searchResp = await fetch(searchUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'ar,en;q=0.5',
        'Referer': 'https://movie.vodu.me/',
      },
      signal: AbortSignal.timeout(10000),
    });

    if (!searchResp.ok) return jsonResp({ error: 'vodu_unavailable', found: false });

    const html = await searchResp.text();

    // استخراج أول نتيجة
    const linkMatch = html.match(/href="(\/(?:movie|show|series|film)[^"]+)"/);
    if (!linkMatch) return jsonResp({ found: false, error: 'not_found_on_vodu' });

    const itemPath = linkMatch[1];
    const itemUrl  = `https://movie.vodu.me${itemPath}`;

    // جلب صفحة العنصر
    const itemResp = await fetch(itemUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://movie.vodu.me/',
      },
      signal: AbortSignal.timeout(10000),
    });

    if (!itemResp.ok) return jsonResp({ found: false, error: 'item_page_failed' });

    const itemHtml = await itemResp.text();

    // استخراج روابط التشغيل
    let playUrl = '';

    // محاولة 1: iframe embed
    const iframeMatch = itemHtml.match(/iframe[^>]+src="([^"]+(?:embed|player|watch)[^"]*)"/i);
    if (iframeMatch) playUrl = iframeMatch[1];

    // محاولة 2: رابط مباشر mp4/m3u8
    if (!playUrl) {
      const mp4Match = itemHtml.match(/(https?:\/\/[^"'\s]+\.(?:mp4|m3u8|mkv)[^"'\s]*)/i);
      if (mp4Match) playUrl = mp4Match[1];
    }

    // محاولة 3: data-src
    if (!playUrl) {
      const dataSrcMatch = itemHtml.match(/data-src="([^"]+(?:mp4|m3u8|stream)[^"]*)"/i);
      if (dataSrcMatch) playUrl = dataSrcMatch[1];
    }

    // للمسلسلات: البحث عن حلقة محددة
    if (type === 'series' && season && episode) {
      const epPattern = new RegExp(`[Ee]p(?:isode)?[\\s._-]?0*${episode}|الحلقة[\\s_-]?0*${episode}`, 'i');
      const epMatch   = itemHtml.match(epPattern);
      if (epMatch) {
        // محاولة استخراج رابط الحلقة المحددة
        const epSection = itemHtml.substring(Math.max(0, itemHtml.indexOf(epMatch[0]) - 100),
                                              itemHtml.indexOf(epMatch[0]) + 500);
        const epUrl = epSection.match(/(https?:\/\/[^"'\s]+\.(?:mp4|m3u8)[^"'\s]*)/i);
        if (epUrl) playUrl = epUrl[1];
      }
    }

    if (!playUrl) return jsonResp({ found: false, item_url: itemUrl, error: 'no_play_url_found' });

    // تحويل لـ https إذا كان http
    const safeUrl = playUrl.startsWith('http:')
      ? '/vodu-stream?url=' + encodeURIComponent(playUrl)
      : playUrl;

    return jsonResp({
      found:      true,
      title,
      play_url:   safeUrl,
      raw_url:    playUrl,
      item_url:   itemUrl,
      source:     'vodu.me',
      ts:         Date.now(),
    });

  } catch (e) {
    return jsonResp({ found: false, error: e.message });
  }
}

// بروكسي لتشغيل روابط vodu عبر https
async function handleVoduStream(request, url) {
  const rawUrl = decodeURIComponent(url.searchParams.get('url') || '');
  if (!rawUrl) return new Response('Missing url', { status: 400 });

  try {
    const range = request.headers.get('Range');
    const resp  = await fetch(rawUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Referer':    'https://movie.vodu.me/',
        ...(range ? { Range: range } : {}),
      },
      signal: AbortSignal.timeout(30000),
    });

    const h = new Headers();
    h.set('Access-Control-Allow-Origin', '*');
    h.set('Access-Control-Expose-Headers', 'Content-Range, Accept-Ranges, Content-Length');
    for (const n of ['Content-Type','Content-Length','Content-Range','Accept-Ranges']) {
      const v = resp.headers.get(n); if (v) h.set(n, v);
    }
    if (!h.get('Content-Type')) h.set('Content-Type', 'video/mp4');

    return new Response(resp.body, { status: resp.status, headers: h });
  } catch (e) {
    return new Response('Vodu stream error: ' + e.message, { status: 502 });
  }
}

// ════════════════════════════════════════════════════════════════
//  IMAGE PROXY — http→https لجميع الصور
//  GET /img?url=https%3A%2F%2F...
// ════════════════════════════════════════════════════════════════
async function handleImgProxy(url) {
  const imgUrl = decodeURIComponent(url.searchParams.get('url') || '');
  if (!imgUrl) return new Response('Missing url', { status: 400 });

  try {
    const r = await fetch(imgUrl, {
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; TOTV+/1.0)' },
      signal: AbortSignal.timeout(8000),
    });
    const h = new Headers();
    h.set('Access-Control-Allow-Origin', '*');
    h.set('Cache-Control', 'public, max-age=86400');
    h.set('Content-Type', r.headers.get('Content-Type') || 'image/jpeg');
    return new Response(r.body, { status: r.status, headers: h });
  } catch (e) {
    return new Response('Image error: ' + e.message, { status: 502 });
  }
}

// ════════════════════════════════════════════════════════════════
//  STREAM PROXY — بروكسي للبث مع دعم Range
//  GET /stream/{type}/{id}.{ext}
// ════════════════════════════════════════════════════════════════
async function handleStream(request, url, env) {
  const parts = url.pathname.replace('/stream/', '').split('/');
  if (parts.length < 2) return new Response('Invalid path', { status: 400 });
  const [type, file] = parts;

  const settings = await getKV(env, KV_SETTINGS) || {};
  const servers  = await getKV(env, KV_SERVERS)  || [];
  const srv      = servers.find(s => s.active !== false) || { host: settings.default_server?.host || '' };

  if (!srv.host) return new Response('No server', { status: 503 });

  const upUrl = `${srv.host.replace(/\/$/, '')}/${type}/${srv.username}/${srv.password}/${file}`;
  const range = request.headers.get('Range');

  try {
    const up = await fetch(upUrl, {
      headers: { 'User-Agent': 'VLC/3.0', ...(range ? { Range: range } : {}) },
    });
    const h = new Headers();
    h.set('Access-Control-Allow-Origin', '*');
    h.set('Access-Control-Expose-Headers', 'Content-Range, Accept-Ranges, Content-Length');
    for (const n of ['Content-Type','Content-Length','Content-Range','Accept-Ranges','ETag']) {
      const v = up.headers.get(n); if (v) h.set(n, v);
    }
    if (!h.get('Content-Type')) {
      const ext = file.split('.').pop()?.toLowerCase();
      const m   = { ts: 'video/MP2T', mp4: 'video/mp4', mkv: 'video/x-matroska', m3u8: 'application/vnd.apple.mpegurl' };
      if (m[ext]) h.set('Content-Type', m[ext]);
    }
    return new Response(up.body, { status: up.status, headers: h });
  } catch (e) {
    return new Response('Stream error: ' + e.message, { status: 502 });
  }
}

// ════════════════════════════════════════════════════════════════
//  HLS PROXY — إعادة كتابة روابط m3u8 لتمر عبر Worker
// ════════════════════════════════════════════════════════════════
async function handleHls(url, env) {
  const parts = url.pathname.replace('/hls/', '').split('/');
  if (parts.length < 2) return new Response('Invalid HLS path', { status: 400 });

  const settings = await getKV(env, KV_SETTINGS) || {};
  const servers  = await getKV(env, KV_SERVERS)  || [];
  const srv      = servers.find(s => s.active !== false) || { host: settings.default_server?.host || '' };

  const [type, file] = parts;
  const streamUrl = `${srv.host?.replace(/\/$/, '') || ''}/${type}/${srv.username || ''}/${srv.password || ''}/${file}`;

  try {
    const r  = await fetch(streamUrl, { headers: { 'User-Agent': 'VLC/3.0' } });
    const ct = r.headers.get('Content-Type') || '';

    if (ct.includes('mpegurl') || file.endsWith('.m3u8')) {
      const text  = await r.text();
      const base  = streamUrl.substring(0, streamUrl.lastIndexOf('/'));
      const m3u8  = text.split('\n').map(line => {
        line = line.trim();
        if (!line || line.startsWith('#')) return line;
        if (line.startsWith('http')) return '/hls/' + type + '/' + line.split('/').pop().split('?')[0];
        return base + '/' + line.split('/').pop().split('?')[0];
      }).join('\n');

      const h = new Headers();
      h.set('Content-Type', 'application/vnd.apple.mpegurl');
      h.set('Access-Control-Allow-Origin', '*');
      h.set('Cache-Control', 'no-cache');
      return new Response(m3u8, { status: 200, headers: h });
    }

    const h = new Headers();
    h.set('Access-Control-Allow-Origin', '*');
    h.set('Content-Type', ct || 'video/MP2T');
    return new Response(r.body, { status: r.status, headers: h });
  } catch (e) {
    return new Response('HLS error: ' + e.message, { status: 502 });
  }
}

// ════════════════════════════════════════════════════════════════
//  VIP STREAM PROXY
// ════════════════════════════════════════════════════════════════
async function handleVipStream(request, url) {
  const rawUrl = url.searchParams.get('url');
  if (!rawUrl) return new Response('Missing url', { status: 400 });

  const range = request.headers.get('Range');
  try {
    const up = await fetch(decodeURIComponent(rawUrl), {
      headers: { 'User-Agent': 'VLC/3.0 LibVLC/3.0', ...(range ? { Range: range } : {}) },
    });
    const h = new Headers();
    h.set('Access-Control-Allow-Origin', '*');
    h.set('Access-Control-Expose-Headers', 'Content-Range, Accept-Ranges, Content-Length');
    for (const n of ['Content-Type','Content-Length','Content-Range','Accept-Ranges']) {
      const v = up.headers.get(n); if (v) h.set(n, v);
    }
    return new Response(up.body, { status: up.status, headers: h });
  } catch (e) {
    return new Response('VIP stream error: ' + e.message, { status: 502 });
  }
}

// ════════════════════════════════════════════════════════════════
//  LEGACY API PROXY — للتوافق مع الكود القديم
// ════════════════════════════════════════════════════════════════
async function handleApiProxy(request, url, env) {
  const action   = url.searchParams.get('action') || '';
  const settings = await getKV(env, KV_SETTINGS) || {};
  const servers  = await getKV(env, KV_SERVERS)  || [];
  const srv      = servers.find(s => s.active !== false);

  const host = srv?.host || settings.default_server?.host || '';
  const user = srv?.username || settings.default_server?.username || '';
  const pass = srv?.password || settings.default_server?.password || '';

  if (!host) return jsonResp({ error: 'no_server_configured' }, 503);

  const params = new URLSearchParams({ username: user, password: pass, action });
  for (const [k, v] of url.searchParams) if (k !== 'action') params.set(k, v);

  try {
    const r = await fetch(`${host.replace(/\/$/, '')}/player_api.php?${params}`, {
      headers: { 'User-Agent': 'TOTV+/1.0', Accept: 'application/json' },
      signal: AbortSignal.timeout(20000),
    });
    const text = await r.text();
    return new Response(text, {
      status: r.status,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
  } catch (e) {
    return jsonResp({ error: e.message }, 502);
  }
}

// ════════════════════════════════════════════════════════════════
//  ADMIN API — جميع عمليات الأدمن
// ════════════════════════════════════════════════════════════════
async function handleAdmin(subpath, request, url, env, ctx) {
  const [section, action] = subpath.split('/');
  let body = {};
  if (request.method === 'POST') {
    try { body = await request.json(); } catch (_) {}
  }

  // ── Servers ──────────────────────────────────────────────────
  if (section === 'servers') {
    if (action === 'list')   return adminServersList(env);
    if (action === 'add')    return adminServersAdd(body, env);
    if (action === 'update') return adminServersUpdate(body, env);
    if (action === 'delete') return adminServersDelete(body, env);
    if (action === 'ping')   return adminServerPing(body);
  }

  // ── Groups ───────────────────────────────────────────────────
  if (section === 'groups') {
    if (action === 'list')   return adminGroupsList(env);
    if (action === 'add')    return adminGroupsAdd(body, env);
    if (action === 'delete') return adminGroupsDelete(body, env);
  }

  // ── Subscriptions ────────────────────────────────────────────
  if (section === 'subs') {
    if (action === 'list')   return adminSubsList(url, env);
    if (action === 'add')    return adminSubsAdd(body, env);
    if (action === 'delete') return adminSubsDelete(body, env);
    if (action === 'stats')  return adminSubsStats(env);
    if (action === 'renew')  return adminSubsRenew(body, env);
  }

  // ── Codes ────────────────────────────────────────────────────
  if (section === 'codes') {
    if (action === 'list')   return adminCodesList(env);
    if (action === 'add')    return adminCodesAdd(body, env);
    if (action === 'bulk')   return adminCodesBulk(body, env);
    if (action === 'delete') return adminCodesDelete(body, env);
    if (action === 'use')    return adminCodesUse(body, env);   // التطبيق يستخدمه
  }

  // ── Notifications ────────────────────────────────────────────
  if (section === 'notif') {
    if (action === 'send')   return adminNotifSend(body, env);
    if (action === 'list')   return adminNotifList(env);
    if (action === 'delete') return adminNotifDelete(body, env);
  }

  // ── Settings ─────────────────────────────────────────────────
  if (section === 'settings') {
    if (action === 'get')    return adminSettingsGet(env);
    if (action === 'save')   return adminSettingsSave(body, env);
  }

  // ── Sections (واجهة المستخدم) ─────────────────────────────
  if (section === 'sections') {
    if (action === 'get')    return adminSectionsGet(url, env);
    if (action === 'save')   return adminSectionsSave(body, env);
  }

  // ── Blocked Channels ─────────────────────────────────────────
  if (section === 'blocked') {
    if (action === 'list')   return adminBlockedList(env);
    if (action === 'add')    return adminBlockedAdd(body, env);
    if (action === 'delete') return adminBlockedDelete(body, env);
  }

  // ── Stats ────────────────────────────────────────────────────
  if (section === 'stats') {
    if (action === 'overview') return adminStatsOverview(env);
    if (action === 'opens')    return adminStatsOpens(url, env);
    if (action === 'online')   return adminStatsOnline(env);
  }

  // ── Content ──────────────────────────────────────────────────
  if (section === 'content') {
    if (action === 'refresh') return adminContentRefresh(body, env, ctx);
  }

  // ── Force FCM push ───────────────────────────────────────────
  if (section === 'push') {
    if (action === 'send')    return adminPushSend(body, env);
  }

  // ── ping (server test) ───────────────────────────────────────
  if (section === 'ping')    return adminServerPing(body);

  return jsonResp({ error: 'unknown_admin_endpoint', path: subpath }, 404);
}

// ── ADMIN: Servers ────────────────────────────────────────────
async function adminServersList(env) {
  const list = await getKV(env, KV_SERVERS) || [];
  return jsonResp(list);
}

async function adminServersAdd(body, env) {
  if (!body.host || !body.username) return jsonResp({ error: 'host and username required' }, 400);
  const list = await getKV(env, KV_SERVERS) || [];
  const srv  = {
    id:       body.id || 'srv_' + Date.now(),
    name:     body.name || body.host,
    host:     body.host.replace(/\/$/, ''),
    username: body.username,
    password: body.password || '',
    type:     body.type || 'free',
    priority: body.priority || 99,
    active:   true,
    added_at: Date.now(),
  };
  list.push(srv);
  await setKV(env, KV_SERVERS, list);
  return jsonResp({ ok: true, server: srv });
}

async function adminServersUpdate(body, env) {
  const list = await getKV(env, KV_SERVERS) || [];
  const idx  = list.findIndex(s => s.id === body.id);
  if (idx < 0) return jsonResp({ error: 'not_found' }, 404);
  list[idx] = { ...list[idx], ...body };
  await setKV(env, KV_SERVERS, list);
  return jsonResp({ ok: true });
}

async function adminServersDelete(body, env) {
  let list = await getKV(env, KV_SERVERS) || [];
  list = list.filter(s => s.id !== body.id);
  await setKV(env, KV_SERVERS, list);
  return jsonResp({ ok: true });
}

async function adminServerPing(body) {
  const host = body.host || '';
  const user = body.username || '';
  const pass = body.password || '';
  if (!host) return jsonResp({ ok: false, error: 'missing_host' });

  const t0  = Date.now();
  const url = `${host.replace(/\/$/, '')}/player_api.php?username=${user}&password=${pass}&action=get_live_categories`;
  try {
    const r  = await fetch(url, { headers: { 'User-Agent': 'TOTV+/1.0' }, signal: AbortSignal.timeout(8000) });
    const ms = Date.now() - t0;
    return jsonResp({ ok: r.ok, ms, status: r.status });
  } catch (e) {
    return jsonResp({ ok: false, ms: Date.now() - t0, error: e.message });
  }
}

// ── ADMIN: Groups ─────────────────────────────────────────────
async function adminGroupsList(env) {
  return jsonResp(await getKV(env, KV_GROUPS) || []);
}

async function adminGroupsAdd(body, env) {
  if (!body.name || !body.server_id) return jsonResp({ error: 'name and server_id required' }, 400);
  const list = await getKV(env, KV_GROUPS) || [];
  const grp  = { id: body.id || 'grp_' + Date.now(), name: body.name, server_id: body.server_id, note: body.note || '', created_at: Date.now() };
  list.push(grp);
  await setKV(env, KV_GROUPS, list);
  return jsonResp({ ok: true, group: grp });
}

async function adminGroupsDelete(body, env) {
  let list = await getKV(env, KV_GROUPS) || [];
  list = list.filter(g => g.id !== body.id);
  await setKV(env, KV_GROUPS, list);
  return jsonResp({ ok: true });
}

// ── ADMIN: Subscriptions ──────────────────────────────────────
async function adminSubsList(url, env) {
  const plan   = url.searchParams.get('plan') || 'all';
  const index  = await getKV(env, KV_SUBS_IDX) || [];
  const subs   = [];
  const limit  = 500;

  for (const id of index.slice(0, limit)) {
    const sub = await getKV(env, KV_SUBS + id);
    if (!sub) continue;
    if (plan !== 'all' && sub.plan !== plan) continue;
    subs.push({ device_id: id, ...sub });
  }
  return jsonResp(subs);
}

async function adminSubsAdd(body, env) {
  if (!body.device_id) return jsonResp({ error: 'device_id required' }, 400);
  const id      = body.device_id;
  const days    = body.days || 30;
  const expiry  = Date.now() + days * 86400000;
  const sub     = { plan: body.plan || 'basic', expiry, created_at: Date.now(), note: body.note || '', renewed_count: 0 };

  await setKV(env, KV_SUBS + id, sub, days * 86400 + 7200);

  // تحديث الفهرس
  const index = await getKV(env, KV_SUBS_IDX) || [];
  if (!index.includes(id)) { index.unshift(id); await setKV(env, KV_SUBS_IDX, index.slice(0, 10000)); }

  return jsonResp({ ok: true, expiry, plan: sub.plan });
}

async function adminSubsRenew(body, env) {
  const id  = body.device_id;
  if (!id) return jsonResp({ error: 'device_id required' }, 400);
  const sub = await getKV(env, KV_SUBS + id);
  if (!sub) return jsonResp({ error: 'not_found' }, 404);

  const days   = body.days || 30;
  const base   = Math.max(sub.expiry, Date.now());
  const expiry = base + days * 86400000;
  const updated = { ...sub, expiry, plan: body.plan || sub.plan, renewed_count: (sub.renewed_count || 0) + 1, last_renewed: Date.now() };
  await setKV(env, KV_SUBS + id, updated, Math.ceil((expiry - Date.now()) / 1000) + 7200);
  return jsonResp({ ok: true, expiry, plan: updated.plan });
}

async function adminSubsDelete(body, env) {
  await env.KV.delete(KV_SUBS + body.device_id);
  return jsonResp({ ok: true });
}

async function adminSubsStats(env) {
  const index = await getKV(env, KV_SUBS_IDX) || [];
  const now   = Date.now();
  let active = 0, expired = 0;
  const plans = { free: 0, basic: 0, normal: 0, vip: 0 };

  for (const id of index.slice(0, 2000)) {
    const sub = await getKV(env, KV_SUBS + id);
    if (!sub) continue;
    if (sub.expiry > now) { active++; plans[sub.plan] = (plans[sub.plan] || 0) + 1; }
    else expired++;
  }
  return jsonResp({ active, expired, total: active + expired, plans });
}

// ── ADMIN: Codes ──────────────────────────────────────────────
async function adminCodesList(env) {
  const index = await getKV(env, KV_CODES_IDX) || [];
  const codes = [];
  for (const code of index.slice(0, 500)) {
    const c = await getKV(env, KV_CODES + code);
    if (c) codes.push({ code, ...c });
  }
  return jsonResp(codes);
}

async function adminCodesAdd(body, env) {
  const code = (body.code || genCode()).toUpperCase().replace(/[^A-Z0-9]/g, '');
  const existing = await getKV(env, KV_CODES + code);
  if (existing) return jsonResp({ error: 'code_exists' }, 409);

  const data = { plan: body.plan || 'basic', days: body.days || 30, used: false, used_by: null, used_at: null, created_at: Date.now(), note: body.note || '' };
  await setKV(env, KV_CODES + code, data, 365 * 86400);

  const index = await getKV(env, KV_CODES_IDX) || [];
  index.unshift(code);
  await setKV(env, KV_CODES_IDX, index.slice(0, 5000));

  return jsonResp({ ok: true, code });
}

async function adminCodesBulk(body, env) {
  const count = Math.min(body.count || 10, 100);
  const codes = [];
  for (let i = 0; i < count; i++) {
    const code = genCode();
    const data = { plan: body.plan || 'basic', days: body.days || 30, used: false, used_by: null, used_at: null, created_at: Date.now() };
    await setKV(env, KV_CODES + code, data, 365 * 86400);
    codes.push(code);
  }
  const index = await getKV(env, KV_CODES_IDX) || [];
  const updated = [...codes, ...index].slice(0, 5000);
  await setKV(env, KV_CODES_IDX, updated);
  return jsonResp({ ok: true, codes });
}

async function adminCodesDelete(body, env) {
  await env.KV.delete(KV_CODES + body.code);
  return jsonResp({ ok: true });
}

// استخدام كود من التطبيق مباشرة
async function adminCodesUse(body, env) {
  const code     = (body.code || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
  const deviceId = body.device_id || '';
  if (!code || !deviceId) return jsonResp({ ok: false, msg: 'بيانات ناقصة' });

  const data = await getKV(env, KV_CODES + code);
  if (!data) return jsonResp({ ok: false, msg: 'الكود غير صحيح أو منتهي' });
  if (data.used && data.used_by !== deviceId) return jsonResp({ ok: false, msg: 'الكود مستخدم على جهاز آخر' });

  const days   = data.days || 30;
  const expiry = Date.now() + days * 86400000;

  // تفعيل الاشتراك
  await adminSubsAdd({ device_id: deviceId, plan: data.plan, days }, env);

  // تحديث الكود
  await setKV(env, KV_CODES + code, { ...data, used: true, used_by: deviceId, used_at: Date.now() });

  return jsonResp({ ok: true, plan: data.plan, days, expiry, msg: 'تم تفعيل الاشتراك بنجاح' });
}

// ── ADMIN: Notifications ──────────────────────────────────────
async function adminNotifSend(body, env) {
  if (!body.title || !body.body) return jsonResp({ error: 'title and body required' }, 400);
  const notif = {
    id:      'n_' + Date.now(),
    title:   body.title,
    body:    body.body,
    type:    body.type    || 'info',
    target:  body.target  || 'all',
    url:     body.url     || '',
    expiry:  body.expiry  || (Date.now() + 7 * 86400000),
    active:  true,
    sent_at: Date.now(),
  };

  const list = await getKV(env, KV_NOTIFS) || [];
  list.unshift(notif);
  await setKV(env, KV_NOTIFS, list.slice(0, 100));

  // إرسال FCM إذا كان هناك Server Key
  if (env.FCM_SERVER_KEY) {
    await sendFCM(env, notif);
  }

  return jsonResp({ ok: true, id: notif.id });
}

async function adminNotifList(env) {
  return jsonResp(await getKV(env, KV_NOTIFS) || []);
}

async function adminNotifDelete(body, env) {
  let list = await getKV(env, KV_NOTIFS) || [];
  list = list.filter(n => n.id !== body.id);
  await setKV(env, KV_NOTIFS, list);
  return jsonResp({ ok: true });
}

// ── ADMIN: Settings ───────────────────────────────────────────
async function adminSettingsGet(env) {
  const settings = await getKV(env, KV_SETTINGS) || {};
  return jsonResp({ ...DEFAULT_SETTINGS, ...settings });
}

async function adminSettingsSave(body, env) {
  const current = await getKV(env, KV_SETTINGS) || {};
  const updated = { ...current, ...body, updated_at: Date.now() };
  await setKV(env, KV_SETTINGS, updated);
  return jsonResp({ ok: true });
}

// ── ADMIN: Sections ───────────────────────────────────────────
async function adminSectionsGet(url, env) {
  const plan = url.searchParams.get('plan') || 'free';
  const data = await getKV(env, KV_SECTIONS + plan);
  return jsonResp(data || defaultSections());
}

async function adminSectionsSave(body, env) {
  const plan     = body.plan || 'free';
  const sections = body.sections || defaultSections();
  await setKV(env, KV_SECTIONS + plan, sections);
  return jsonResp({ ok: true });
}

function defaultSections() {
  return [
    { id: 'live',    name: 'قنوات مباشرة', visible: true  },
    { id: 'movies',  name: 'أفلام',         visible: true  },
    { id: 'series',  name: 'مسلسلات',       visible: true  },
    { id: 'sports',  name: 'رياضة',          visible: true  },
    { id: 'kids',    name: 'أطفال',          visible: true  },
    { id: 'news',    name: 'أخبار',           visible: false },
  ];
}

// ── ADMIN: Blocked Channels ───────────────────────────────────
async function adminBlockedList(env) {
  return jsonResp(await getKV(env, KV_BLOCKED) || []);
}

async function adminBlockedAdd(body, env) {
  const list = await getKV(env, KV_BLOCKED) || [];
  if (!list.includes(body.id)) { list.push(body.id); await setKV(env, KV_BLOCKED, list); }
  return jsonResp({ ok: true });
}

async function adminBlockedDelete(body, env) {
  let list = await getKV(env, KV_BLOCKED) || [];
  list = list.filter(id => id !== body.id);
  await setKV(env, KV_BLOCKED, list);
  return jsonResp({ ok: true });
}

// ── ADMIN: Stats ──────────────────────────────────────────────
async function adminStatsOverview(env) {
  const subsStats  = await adminSubsStats(env).then(r => r.json()).catch(() => ({}));
  const servers    = await getKV(env, KV_SERVERS) || [];
  const codesIdx   = await getKV(env, KV_CODES_IDX) || [];

  return jsonResp({
    subs:           subsStats,
    servers_total:  servers.length,
    servers_active: servers.filter(s => s.active !== false).length,
    codes_total:    codesIdx.length,
    ts:             Date.now(),
  });
}

async function adminStatsOpens(url, env) {
  const days  = parseInt(url.searchParams.get('days') || '7');
  const result = [];
  const now   = new Date();

  for (let i = days - 1; i >= 0; i--) {
    const d    = new Date(now);
    d.setDate(d.getDate() - i);
    const key  = d.toISOString().slice(0, 10);
    const data = await getKV(env, KV_OPENS + key) || { total: 0, plans: {} };
    result.push({ date: key, total: data.total || 0, plans: data.plans || {} });
  }
  return jsonResp(result);
}

async function adminStatsOnline(env) {
  // المستخدمون المتصلون في آخر 2 دقيقة
  // Cloudflare KV لا يدعم list بسهولة — نرجع عدد تقريبي
  return jsonResp({ count: 0, note: 'Use Firebase Firestore online_users collection for real-time count' });
}

// ── ADMIN: Content Refresh ────────────────────────────────────
async function adminContentRefresh(body, env, ctx) {
  const type = body.type || 'all';
  const types = type === 'all' ? ['movies', 'series', 'live'] : [type];
  ctx.waitUntil(Promise.all(types.map(t => refreshContent(env, t))));
  return jsonResp({ ok: true, refreshing: types });
}

// ── ADMIN: FCM Push ───────────────────────────────────────────
async function adminPushSend(body, env) {
  if (!body.title || !body.body) return jsonResp({ error: 'title and body required' }, 400);
  const notif = { title: body.title, body: body.body, type: body.type || 'info', target: body.target || 'all', url: body.url || '' };
  const r = await sendFCM(env, notif);
  return jsonResp({ ok: true, fcm: r });
}

// ════════════════════════════════════════════════════════════════
//  HEALTH & VERSION
// ════════════════════════════════════════════════════════════════
async function handleHealth(env) {
  const servers = await getKV(env, KV_SERVERS) || [];
  const active  = servers.filter(s => s.active !== false);
  const settings = await getKV(env, KV_SETTINGS) || {};
  const merged   = { ...DEFAULT_SETTINGS, ...settings };

  return jsonResp({
    ok: true,
    version: 'cms_v1.0',
    servers_total:  servers.length,
    servers_active: active.length,
    maintenance:    merged.maintenance || false,
    ts: Date.now(),
  });
}

async function handleVersion(env) {
  const settings = await getKV(env, KV_SETTINGS) || {};
  const merged   = { ...DEFAULT_SETTINGS, ...settings };
  return jsonResp({
    required:  merged.min_version || 18,
    latest:    merged.min_version || 18,
    updateUrl: merged.update_url  || DEFAULT_SETTINGS.update_url,
    ts: Date.now(),
  });
}

// ════════════════════════════════════════════════════════════════
//  HELPERS
// ════════════════════════════════════════════════════════════════

// KV helpers
async function getKV(env, key) {
  try {
    const v = await env.KV.get(key);
    return v ? JSON.parse(v) : null;
  } catch (_) { return null; }
}

async function setKV(env, key, value, ttlSecs) {
  try {
    const opts = ttlSecs ? { expirationTtl: ttlSecs } : {};
    await env.KV.put(key, JSON.stringify(value), opts);
  } catch (_) {}
}

// تحويل http → https عبر Worker proxy
function toHttpsProxy(url) {
  if (!url) return '';
  if (url.startsWith('https://')) return url;
  // يمر عبر Worker نفسه كـ proxy
  return 'REPLACE_WITH_YOUR_WORKER_URL/stream/';
  // ملاحظة: يُستبدل بعنوان Worker الفعلي عند النشر
}

// Auth check
function checkAdminToken(request, env) {
  const token   = request.headers.get('X-Admin-Token') || request.headers.get('Authorization')?.replace('Bearer ', '');
  const envToken = env.ADMIN_TOKEN || 'totv_admin_2024';
  return token === envToken;
}

// FCM
async function sendFCM(env, notif) {
  if (!env.FCM_SERVER_KEY) return { skipped: true };
  const topicMap = { all: '/topics/all_users', free: '/topics/free_users', basic: '/topics/premium_users', normal: '/topics/premium_users', vip: '/topics/premium_users' };
  const to = topicMap[notif.target] || '/topics/all_users';

  try {
    const r = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: 'key=' + env.FCM_SERVER_KEY },
      body: JSON.stringify({
        to,
        notification: { title: notif.title, body: notif.body, sound: 'default' },
        data:         { type: notif.type || 'info', url: notif.url || '', notif_id: notif.id || '' },
        priority:     'high',
      }),
    });
    return await r.json();
  } catch (e) {
    return { error: e.message };
  }
}

// تتبع فتح التطبيق
async function trackOpen(env, deviceId, plan) {
  try {
    const today = new Date().toISOString().slice(0, 10);
    const key   = KV_OPENS + today;
    const data  = await getKV(env, key) || { total: 0, plans: {} };
    data.total++;
    data.plans[plan] = (data.plans[plan] || 0) + 1;
    await setKV(env, key, data, 8 * 86400); // 8 أيام
  } catch (_) {}
}

// تتبع المستخدمين المتصلين
async function trackOnline(env, deviceId, plan) {
  try {
    await setKV(env, KV_ONLINE + deviceId, { plan, ts: Date.now() }, TTL_ONLINE);
  } catch (_) {}
}

// توليد كود عشوائي
function genCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code    = '';
  for (let i = 0; i < 8; i++) {
    if (i === 4) code += '-';
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

// CORS preflight
function preflight() {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin':  '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-Admin-Token, Authorization, Range',
      'Access-Control-Max-Age':       '86400',
    },
  });
}

function jsonResp(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  });
}
