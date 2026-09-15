// Astro Neighbor engine cache (tools/web/astro-engine-sw.js, copied into the export by publish_web.sh).
//
// WHY: the engine (index.wasm, ~39.5 MB, ~10 MB gzipped) is the same file on almost every deploy, but
// GitHub Pages gives every file a new ETag on every deploy, so a phone on mobile data re-downloaded it
// after every update. This worker keeps ONE copy of the engine, keyed by its sha256.
//
// THE RULES (keep them this strict):
// * It only ever CACHES   <this folder>/index.wasm?h=<64 hex>   - nothing else. Page loads (index.html)
//   are not touched at all. Every other GET in this folder (index.js, index.pck, worklets, icons) is
//   passed straight through with fetch(request): the browser's normal HTTP cache and ETag revalidation
//   apply, and nothing is put in Cache Storage. WHY THE PASS-THROUGH, measured in a WKWebView against a
//   GitHub-Pages-like server (2026-09-14): when a worker has a fetch handler and simply does not answer,
//   WebKit's fallback load skipped the HTTP cache for index.pck - 13.9 MB re-downloaded on EVERY visit
//   with no deploy (3 of 3 visits at max-age=600 and 3 of 3 at max-age=5; index.js too), where the same
//   page with no worker sent 0 bytes (cache hit or 304). fetch(request) from the worker restored the
//   304s / cache hits for index.pck.
// * The cache key IS the hash the page asked for (cache "astro-engine-<sha256>"), so a page from a new
//   build is always a cache miss. Nothing is stored unless the downloaded bytes hash to that sha256. On a
//   mismatch (a deploy landed mid-load, so the page and the engine are from different builds) the
//   response ERRORS instead of completing, so a stale page and a new engine are never combined; the
//   page reloads once.
// * As soon as an engine is served or stored for one hash, every other "astro-engine-*" cache is deleted
//   (one engine on the phone at a time). It never touches other caches: baglbot8.github.io is shared by
//   every Pages site of that account.
// * The worker's URL and bytes do NOT change per build. MEASURED 2026-09-14: the first version registered
//   astro-engine-sw.js?h=<sha256>, so every engine deploy swapped workers while the page was loading; the
//   old worker was stopped in the middle of passing index.js through and the game failed to boot
//   ("Can't find variable: Engine") on 1 of the 2 engine-deploy visits tested. So the hash lives only in
//   the engine request, and a CODE change to this file waits (no skipWaiting) until no tab uses the old
//   worker. skipWaiting is used only when there is no engine worker yet (first visit, or replacing the
//   old Godot PWA worker - the page reloads itself in that case).
// * The kill switch lives in index.html (publish with ASTRO_ENGINE_CACHE=off): the page unregisters this
//   worker and deletes its caches itself, without needing this file to cooperate.
//
// index.service.worker.js is a DIFFERENT file (the constant self-destructing killer of the old PWA
// worker). Never merge the two.
'use strict';

const PREFIX = 'astro-engine-';
const HEX64 = /^[0-9a-f]{64}$/;
const ENGINE_PATH = new URL('index.wasm', self.location.href).pathname;
const FOLDER = new URL('./', self.location.href).pathname;

self.addEventListener('install', () => {
	const active = self.registration.active;
	if (!active || active.scriptURL.indexOf('/astro-engine-sw.js') === -1) self.skipWaiting();
});

self.addEventListener('activate', (event) => {
	event.waitUntil(self.clients.claim().catch(() => {}));
});

async function keepOnly(name) {
	try {
		const keys = await caches.keys();
		await Promise.all(keys.filter((k) => k.indexOf(PREFIX) === 0 && k !== name).map((k) => caches.delete(k)));
	} catch (e) { /* the next visit tries again */ }
}

// A page that is not controlled (a hard reload bypasses the worker) asks to be claimed instead of
// downloading the engine again.
self.addEventListener('message', (event) => {
	if (event.data && event.data.type === 'astro-engine-claim') {
		event.waitUntil(self.clients.claim().catch(() => {}));
	}
});

self.addEventListener('fetch', (event) => {
	const req = event.request;
	if (req.method !== 'GET') return;
	let url;
	try { url = new URL(req.url); } catch (e) { return; }
	if (req.mode === 'navigate') return; // pages always load exactly as if there were no worker
	if (url.origin !== self.location.origin || url.pathname.indexOf(FOLDER) !== 0) return;
	const h = url.searchParams.get('h');
	// Only the exact form index.wasm?h=<sha256> is served by serveEngine. Everything else in this folder
	// (plain index.wasm from a kill-switch page included) is a pass-through: see WHY THE PASS-THROUGH.
	if (url.pathname !== ENGINE_PATH || !h || !HEX64.test(h) || url.search !== '?h=' + h) {
		if (req.cache === 'only-if-cached' && req.mode !== 'same-origin') return;
		event.respondWith(fetch(req));
		return;
	}
	let finish;
	const background = new Promise((resolve) => { finish = resolve; });
	event.waitUntil(background);
	event.respondWith(serveEngine(event, url.href, h, finish).catch((err) => {
		finish();
		throw err;
	}));
});

async function serveEngine(event, key, h, finish) {
	try {
		const hit = await caches.match(key, { cacheName: PREFIX + h });
		if (hit && hit.body) {
			keepOnly(PREFIX + h).then(finish, finish);
			return new Response(hit.body, { status: 200, headers: engineHeaders('cache') });
		}
	} catch (e) { /* no cache available: fall through to the network */ }
	// no-cache: revalidate with the server, so a mismatched body sitting in the HTTP cache is not
	// replayed on the retry. An unchanged file costs one 304.
	const net = await fetch(key, { credentials: 'same-origin', cache: 'no-cache' });
	if (!net.ok || !net.body) {
		finish();
		return net;
	}
	const hasher = new Sha256();
	const chunks = [];
	const reader = net.body.getReader();
	let held = null; // the newest chunk is held back until the hash is known
	let settled = false;
	const settle = (ok) => {
		if (settled) return;
		settled = true;
		if (!ok) { chunks.length = 0; finish(); return; }
		(async () => {
			try {
				const cache = await caches.open(PREFIX + h);
				const blob = new Blob(chunks, { type: 'application/wasm' });
				chunks.length = 0;
				await cache.put(key, new Response(blob, { status: 200, headers: { 'Content-Type': 'application/wasm' } }));
				await keepOnly(PREFIX + h);
			} catch (e) { /* quota or eviction: the engine just is not cached this time */ }
			chunks.length = 0;
			finish();
		})();
	};
	const stream = new ReadableStream({
		async pull(controller) {
			for (;;) {
				let r;
				try {
					r = await reader.read();
				} catch (e) {
					controller.error(e);
					settle(false);
					return;
				}
				if (r.done) {
					const got = hasher.hex();
					if (got !== h) {
						notify(event, { type: 'astro-engine-mismatch', want: h, got: got });
						controller.error(new TypeError('astro engine sha256 mismatch'));
						settle(false);
						return;
					}
					if (held) controller.enqueue(held);
					held = null;
					controller.close();
					settle(true);
					return;
				}
				const chunk = r.value;
				hasher.update(chunk);
				chunks.push(chunk);
				const prev = held;
				held = chunk;
				if (prev) {
					controller.enqueue(prev);
					return;
				}
			}
		},
		cancel(reason) {
			settle(false);
			return reader.cancel(reason);
		},
	});
	return new Response(stream, { status: 200, headers: engineHeaders('network') });
}

function engineHeaders(source) {
	return { 'Content-Type': 'application/wasm', 'X-Astro-Engine': source };
}

function notify(event, msg) {
	try {
		self.clients.get(event.clientId).then((c) => { if (c) c.postMessage(msg); }).catch(() => {});
	} catch (e) { /* no client */ }
}

// Incremental SHA-256 (FIPS 180-4), so the engine is hashed as it streams instead of being copied into
// one more 40 MB buffer. Checked against node's crypto on the real 39.5 MB index.wasm (2026-09-14).
const K256 = new Int32Array([
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
]);

class Sha256 {
	constructor() {
		this.s = new Int32Array([0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]);
		this.w = new Int32Array(64);
		this.buf = new Uint8Array(64);
		this.bufLen = 0;
		this.total = 0;
	}

	update(data) {
		const n = data.length;
		let i = 0;
		this.total += n;
		if (this.bufLen > 0) {
			const take = Math.min(64 - this.bufLen, n);
			this.buf.set(data.subarray(0, take), this.bufLen);
			this.bufLen += take;
			i = take;
			if (this.bufLen === 64) {
				this.block(this.buf, 0);
				this.bufLen = 0;
			}
		}
		for (; i + 64 <= n; i += 64) this.block(data, i);
		if (i < n) {
			this.buf.set(data.subarray(i), 0);
			this.bufLen = n - i;
		}
	}

	block(d, o) {
		const w = this.w;
		const s = this.s;
		for (let t = 0; t < 16; t++) {
			const j = o + t * 4;
			w[t] = (d[j] << 24) | (d[j + 1] << 16) | (d[j + 2] << 8) | d[j + 3];
		}
		for (let t = 16; t < 64; t++) {
			const x = w[t - 2];
			const y = w[t - 15];
			const s1 = ((x >>> 17) | (x << 15)) ^ ((x >>> 19) | (x << 13)) ^ (x >>> 10);
			const s0 = ((y >>> 7) | (y << 25)) ^ ((y >>> 18) | (y << 14)) ^ (y >>> 3);
			w[t] = (((s1 + w[t - 7]) | 0) + ((s0 + w[t - 16]) | 0)) | 0;
		}
		let a = s[0], b = s[1], c = s[2], dd = s[3], e = s[4], f = s[5], g = s[6], h = s[7];
		for (let t = 0; t < 64; t++) {
			const t1 = (((((h + (((e >>> 6) | (e << 26)) ^ ((e >>> 11) | (e << 21)) ^ ((e >>> 25) | (e << 7)))) | 0)
				+ ((e & f) ^ (~e & g))) | 0) + ((K256[t] + w[t]) | 0)) | 0;
			const t2 = ((((a >>> 2) | (a << 30)) ^ ((a >>> 13) | (a << 19)) ^ ((a >>> 22) | (a << 10)))
				+ ((a & b) ^ (a & c) ^ (b & c))) | 0;
			h = g;
			g = f;
			f = e;
			e = (dd + t1) | 0;
			dd = c;
			c = b;
			b = a;
			a = (t1 + t2) | 0;
		}
		s[0] = (s[0] + a) | 0; s[1] = (s[1] + b) | 0; s[2] = (s[2] + c) | 0; s[3] = (s[3] + dd) | 0;
		s[4] = (s[4] + e) | 0; s[5] = (s[5] + f) | 0; s[6] = (s[6] + g) | 0; s[7] = (s[7] + h) | 0;
	}

	hex() {
		const bits = this.total * 8;
		const pad = new Uint8Array(((this.bufLen < 56) ? 56 : 120) - this.bufLen + 8);
		pad[0] = 0x80;
		const hi = Math.floor(bits / 4294967296);
		const lo = bits >>> 0;
		const p = pad.length - 8;
		pad[p] = hi >>> 24; pad[p + 1] = hi >>> 16; pad[p + 2] = hi >>> 8; pad[p + 3] = hi;
		pad[p + 4] = lo >>> 24; pad[p + 5] = lo >>> 16; pad[p + 6] = lo >>> 8; pad[p + 7] = lo;
		const total = this.total;
		this.update(pad);
		this.total = total;
		let out = '';
		for (let i = 0; i < 8; i++) out += (this.s[i] >>> 0).toString(16).padStart(8, '0');
		return out;
	}
}
