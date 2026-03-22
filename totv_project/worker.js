// TOTV+ Gateway Worker v6.0
// *** هذا الإصدار للـ Cloudflare Dashboard (Copy/Paste) ***
// *** للـ Wrangler CLI استخدم worker.js ***

const TTL = {
  live_streams: 120, live_categories: 60,
  vod_streams: 600,  vod_categories: 300, vod_info: 1800,
  series: 600,       series_categories: 300, series_info: 1800,
  stale_factor: 2,
};
const CB_THRESHOLD  = 5;
const CB_TIMEOUT_MS = 30000;
const coalesce      = new Map();
let cbFailures = 0;
let cbOpenAt   = 0;

// ── Service Worker format ─────────────────────────────────
addEventListener("fetch", event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  if (request.method === "OPTIONS") return preflightResp();
  const url  = new URL(request.url);
  const path = url.pathname;
  if (path === "/health")             return handleHealth();
  if (path === "/version")            return handleVersion();
  if (path.startsWith("/icon/"))      return handleIcon(url);
  if (path.startsWith("/stream/"))    return handleStream(request, url);
  if (path.startsWith("/vip-stream/")) return handleVipStream(request, url);
  if (path === "/lb-status")           return handleLbStatus();
  if (path.startsWith("/hls/"))       return handleHls(url);
  if (url.searchParams.has("action")) return handleApi(request, url);
  if (path.startsWith("/img/"))       return handleImageProxy(url);
  // Root path — إذا لم يكن هناك action
  if (path === "/" || path === "/player_api.php")
    return jsonResp({ status: "TOTV+ Worker v6 OK", usage: "Add ?action=get_live_streams" }, 200);
  return jsonResp({ error: "not_found", path }, 404);
}

// ══ Server Config (يُعدَّل مباشرة هنا إذا لم تستخدم Secrets) ═
const SERVER = {
  host: "http://usmmax.org:2052",
  user: "28701367011637",
  pass: "26997520760476",
};

async function handleApi(request, url) {
  const action   = url.searchParams.get("action") || "";
  const cacheKey = buildCacheKey(action, url);
  const ttl      = getTtl(action);

  if (coalesce.has(cacheKey)) {
    try { return apiResp(await coalesce.get(cacheKey)); } catch (_) {}
  }

  const promise = fetchFromServer(action, url).then(data => {
    coalesce.delete(cacheKey);
    return data;
  }).catch(err => { coalesce.delete(cacheKey); throw err; });

  coalesce.set(cacheKey, promise);
  try {
    return apiResp(await promise);
  } catch (e) {
    return jsonResp({ error: e.message }, 502);
  }
}

async function handleStream(request, url) {
  const parts = url.pathname.replace("/stream/", "").split("/");
  if (parts.length < 2) return new Response("Invalid path", { status: 400 });
  const [type, file] = parts;
  const upUrl = `${SERVER.host}/${type}/${SERVER.user}/${SERVER.pass}/${file}`;
  const range = request.headers.get("Range");
  try {
    const up = await fetch(upUrl, {
      headers: {
        "User-Agent": "VLC/3.0",
        ...(range ? { "Range": range } : {}),
      },
    });
    const h = new Headers();
    h.set("Access-Control-Allow-Origin", "*");
    h.set("Access-Control-Expose-Headers", "Content-Range, Accept-Ranges, Content-Length");
    for (const n of ["Content-Type","Content-Length","Content-Range","Accept-Ranges","ETag"]) {
      const v = up.headers.get(n); if (v) h.set(n, v);
    }
    if (!h.get("Content-Type")) {
      const ext = file.split(".").pop()?.toLowerCase();
      const m = { ts:"video/MP2T", mp4:"video/mp4", mkv:"video/x-matroska" };
      if (m[ext]) h.set("Content-Type", m[ext]);
    }
    return new Response(up.body, { status: up.status, headers: h });
  } catch (e) { return new Response("Stream error: " + e.message, { status: 502 }); }
}

async function handleHls(url) {
  const parts = url.pathname.replace("/hls/", "").split("/");
  if (parts.length < 2) return new Response("Invalid HLS path", { status: 400 });
  const [type, id] = parts;

  // جرب m3u8 أولاً ثم ts مباشرة
  const m3u8Url = `${SERVER.host}/${type}/${SERVER.user}/${SERVER.pass}/${id}`;

  try {
    const res = await fetch(m3u8Url, {
      headers: { "User-Agent": "VLC/3.0 LibVLC/3.0" },
    });

    const ct = res.headers.get("Content-Type") || "";

    // إذا كان الرد m3u8 — أعد كتابة الروابط
    if (res.ok && (ct.includes("mpegurl") || ct.includes("x-mpegURL") || m3u8Url.endsWith(".m3u8"))) {
      let m3u8 = await res.text();
      const base = url.origin + "/stream/" + type;

      // أعد كتابة روابط TS
      m3u8 = m3u8.replace(/^(?!#)(.+)$/gm, line => {
        line = line.trim();
        if (!line) return line;
        if (line.startsWith("#")) return line;
        // رابط كامل
        if (line.startsWith("http")) {
          const fname = line.split("/").pop().split("?")[0];
          return base + "/" + fname;
        }
        // رابط نسبي
        return base + "/" + line.split("/").pop().split("?")[0];
      });

      const h = new Headers();
      h.set("Content-Type", "application/vnd.apple.mpegurl");
      h.set("Access-Control-Allow-Origin", "*");
      h.set("Cache-Control", "no-cache, no-store");
      h.set("Access-Control-Allow-Headers", "Range, Origin");
      return new Response(m3u8, { status: 200, headers: h });
    }

    // إذا لم يكن m3u8 — مرر مباشرة كـ stream
    const h = new Headers();
    h.set("Access-Control-Allow-Origin", "*");
    h.set("Content-Type", ct || "video/MP2T");
    h.set("Cache-Control", "no-cache");
    return new Response(res.body, { status: res.status, headers: h });

  } catch (e) {
    return new Response("HLS error: " + e.message, { status: 502 });
  }
}

async function fetchFromServer(action, url) {
  if (cbFailures >= CB_THRESHOLD) {
    const elapsed = Date.now() - cbOpenAt;
    if (elapsed < CB_TIMEOUT_MS)
      throw new Error("Circuit open — retry in " + Math.ceil((CB_TIMEOUT_MS - elapsed) / 1000) + "s");
    cbFailures = CB_THRESHOLD - 1;
  }
  const p = new URLSearchParams({ username: SERVER.user, password: SERVER.pass, action });
  for (const [k, v] of url.searchParams) if (k !== "action") p.set(k, v);
  const apiUrl = SERVER.host + "/player_api.php?" + p;
  for (let i = 0; i < 3; i++) {
    try {
      const res = await fetch(apiUrl, {
        headers: { "User-Agent": "TOTV+/6.0", "Accept": "application/json" },
      });
      if (res.ok) { cbFailures = 0; return await res.text(); }
      if (![429,502,503,504].includes(res.status)) throw new Error("Server " + res.status);
      if (i < 2) { await sleep(300 * Math.pow(2, i)); continue; }
      throw new Error("Server error: " + res.status);
    } catch (e) {
      if (i < 2) { await sleep(300 * Math.pow(2, i)); continue; }
      cbFailures++;
      if (cbFailures >= CB_THRESHOLD) cbOpenAt = Date.now();
      throw e;
    }
  }
}

async function handleIcon(url) {
  const id = url.pathname.replace("/icon/", "");
  try {
    const r = await fetch(SERVER.host + "/picons/" + id, { headers: { "User-Agent": "TOTV+/6.0" } });
    const h = new Headers(r.headers);
    h.set("Access-Control-Allow-Origin", "*");
    h.set("Cache-Control", "public, max-age=86400");
    return new Response(r.body, { status: r.status, headers: h });
  } catch (_) { return new Response("Icon error", { status: 502 }); }
}

function handleVersion() {
  return jsonResp({ required: 12, latest: 12, updateUrl: "https://hamza123123123.github.io/totv/#", ts: Date.now() });
}

async function handleHealth() {
  const s = { ok: true, ts: Date.now(), cb: cbFailures };
  try {
    const t0 = Date.now();
    const r = await fetch(
      SERVER.host + "/player_api.php?username=" + SERVER.user + "&password=" + SERVER.pass + "&action=get_live_categories",
      { headers: { "User-Agent": "TOTV+/6.0" } }
    );
    s.ms = Date.now() - t0;
    s.up = r.ok;
  } catch (e) { s.up = false; s.err = e.message; }
  return jsonResp(s);
}

function buildCacheKey(action, url) {
  const e = [];
  for (const [k, v] of url.searchParams) if (k !== "action") e.push(k + "=" + v);
  return "v6:" + action + (e.length ? ":" + e.join(":") : "");
}

function getTtl(action) {
  const m = {
    get_live_streams: TTL.live_streams, get_live_categories: TTL.live_categories,
    get_vod_streams: TTL.vod_streams,   get_vod_categories: TTL.vod_categories,
    get_vod_info: TTL.vod_info,         get_series: TTL.series,
    get_series_categories: TTL.series_categories, get_series_info: TTL.series_info,
  };
  return m[action] || 0;
}

function preflightResp() {
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin":  "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Range",
      "Access-Control-Max-Age":       "86400",
    },
  });
}

function jsonResp(data, status) {
  return new Response(JSON.stringify(data), {
    status: status || 200,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}

function apiResp(text, extra) {
  return new Response(text, {
    status: 200,
    headers: Object.assign({ "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }, extra || {}),
  });
}


// ── Image Proxy — يحل CORS للصور الخارجية (blogger, darlogo, etc) ──
async function handleImageProxy(url) {
  // /img/?url=https%3A%2F%2Fblogger.com%2Fimage.png
  const imgUrl = url.searchParams.get("url");
  if (!imgUrl) return new Response("Missing url param", { status: 400 });
  try {
    const r = await fetch(decodeURIComponent(imgUrl), {
      headers: { "User-Agent": "Mozilla/5.0 (compatible; TOTV+/12)" },
    });
    const h = new Headers();
    h.set("Access-Control-Allow-Origin", "*");
    h.set("Cache-Control", "public, max-age=86400");
    const ct = r.headers.get("Content-Type") || "image/jpeg";
    h.set("Content-Type", ct);
    return new Response(r.body, { status: r.status, headers: h });
  } catch (e) {
    return new Response("Image proxy error: " + e.message, { status: 502 });
  }
}


// ══ VIP Stream Proxy — اتصال مباشر لمشتركي VIP ══════════
async function handleVipStream(request, url) {
  // /vip-stream/{type}/{vipUser}/{vipPass}/{file}?host=...
  const parts = url.pathname.replace("/vip-stream/", "").split("/");
  if (parts.length < 4) return new Response("Invalid VIP stream path", { status: 400 });

  const [type, vipUser, vipPass, file] = parts;
  const host = url.searchParams.get("host") || SERVER.host;
  const cleanHost = host.replace(/\/$/, "");
  const streamUrl = `${cleanHost}/${type}/${vipUser}/${vipPass}/${file}`;

  const range = request.headers.get("Range");
  try {
    const up = await fetch(streamUrl, {
      headers: {
        "User-Agent": "VLC/3.0 LibVLC/3.0",
        ...(range ? { "Range": range } : {}),
      },
    });
    const h = new Headers();
    h.set("Access-Control-Allow-Origin", "*");
    h.set("Access-Control-Expose-Headers", "Content-Range, Accept-Ranges, Content-Length");
    for (const n of ["Content-Type","Content-Length","Content-Range","Accept-Ranges","ETag"]) {
      const v = up.headers.get(n); if (v) h.set(n, v);
    }
    if (!h.get("Content-Type")) {
      const ext = file.split(".").pop()?.toLowerCase();
      const m = { ts:"video/MP2T", mp4:"video/mp4", mkv:"video/x-matroska" };
      if (m[ext]) h.set("Content-Type", m[ext]);
    }
    return new Response(up.body, { status: up.status, headers: h });
  } catch (e) { return new Response("VIP stream error: " + e.message, { status: 502 }); }
}

// ══ Load Balancer Status ══════════════════════════════════
function handleLbStatus() {
  return new Response(JSON.stringify({
    status: "ok",
    server: SERVER.host,
    cb_failures: cbFailures,
    ts: Date.now()
  }), {
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
  });
}

function sleep(ms) { return new Promise(function(r) { setTimeout(r, ms); }); }
