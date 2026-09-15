// Astro Neighbor engine cache, page side (tools/web/engine_cache_head.js). publish_web.sh inlines this
// into index.html's <head> with the engine's sha256 and the kill switch filled in. See astro-engine-sw.js
// for the rules. It only changes ONE request: Godot's loader calls fetch('index.wasm'); this turns that
// into index.wasm?h=<sha256> and, on a first visit, waits (at most WAIT_MS) for the engine worker to
// take control so the one download is also the one that gets cached. The worker URL is constant
// (astro-engine-sw.js, no hash): the hash travels only in the engine request - see the worker's header. If Godot ever renames that
// request, nothing matches and the game simply loads from the network as before.
(function () {
	var HASH = '__ASTRO_ENGINE_SHA256__';
	var PCK_HASH = '__ASTRO_PCK_SHA256__'; // cache-buster only: index.pck is NEVER put in Cache Storage
	var ENABLED = __ASTRO_ENGINE_CACHE_ENABLED__; // the kill switch: false unregisters the worker and empties its caches
	var SW = 'astro-engine-sw.js';
	var PREFIX = 'astro-engine-';
	var WAIT_MS = 4000;
	var info = window.__astroEngine = { hash: HASH, enabled: ENABLED, controlled: false, source: '', state: 'starting' };
	var sw = null;
	try { sw = ('serviceWorker' in navigator) ? navigator.serviceWorker : null; } catch (e) { sw = null; }
	var usable = !!(sw && typeof caches !== 'undefined' && window.isSecureContext && typeof ReadableStream !== 'undefined');

	function isEngineWorker(w) { return !!(w && w.scriptURL && w.scriptURL.slice(-(SW.length + 1)) === '/' + SW); }
	function controlledByMine() { return isEngineWorker(sw && sw.controller); }

	// A device that still has the OLD Godot PWA worker (index.service.worker.js, shipped before 2026-09-06)
	// would otherwise have its registration silently replaced by ours below, so the constant killer never
	// runs, its dead cache (old index.pck and index.wasm) stays on disk, and THIS visit's index.pck still
	// comes out of that cache - an old build under a new page (measured in the WebKit test, 2026-09-14).
	// So: unregister it here, delete its caches, and reload once if it controls this page. The killer file
	// stays published for pages the old worker serves from its cache (they never run this script).
	var OLD_SW = '/index.service.worker.js';
	var OLD_CACHE = 'Astro Neighbor-sw-cache-';
	function isOld(w) { return !!(w && w.scriptURL && w.scriptURL.slice(-OLD_SW.length) === OLD_SW); }
	var pre = Promise.resolve();
	if (sw) {
		pre = sw.getRegistration().then(function (reg) {
			var found = !!(reg && (isOld(reg.active) || isOld(reg.waiting) || isOld(reg.installing)));
			var jobs = [];
			if (found) jobs.push(reg.unregister());
			if (typeof caches !== 'undefined') {
				jobs.push(caches.keys().then(function (ks) {
					return Promise.all(ks.filter(function (k) { return k.indexOf(OLD_CACHE) === 0; }).map(function (k) { return caches.delete(k); }));
				}));
			}
			return Promise.all(jobs).then(function () { return found; });
		}).then(function (found) {
			if (!found) return;
			info.oldPwa = 'removed';
			if (!isOld(sw.controller)) return;
			var key = 'astro-oldpwa-reload';
			var tried = true;
			try {
				tried = sessionStorage.getItem(key) === '1';
				if (!tried) sessionStorage.setItem(key, '1');
			} catch (e) { tried = true; }
			if (tried) return;
			info.state = 'old-pwa-reload';
			location.reload();
			return new Promise(function () {}); // hold every game download until the reload
		}).catch(function () { /* never block the game on cleanup */ });
	}

	var ready;
	if (!ENABLED) {
		// Kill switch. Runs on the page, so it works even if the worker itself is broken.
		var jobs = [];
		if (sw) {
			jobs.push(pre.then(function () { return sw.getRegistrations(); }).then(function (rs) {
				return Promise.all(rs.map(function (r) {
					if (isEngineWorker(r.active) || isEngineWorker(r.waiting) || isEngineWorker(r.installing)) return r.unregister();
					return null;
				}));
			}));
		}
		if (typeof caches !== 'undefined') {
			jobs.push(caches.keys().then(function (ks) {
				return Promise.all(ks.filter(function (k) { return k.indexOf(PREFIX) === 0; }).map(function (k) { return caches.delete(k); }));
			}));
		}
		ready = pre.then(function () { return Promise.all(jobs); }).then(function () { info.state = 'killed'; }, function () { info.state = 'kill-failed'; });
	} else if (usable) {
		ready = pre.then(function () { return new Promise(function (resolve) {
			var done = false;
			function finish(state) {
				if (done) return;
				done = true;
				info.state = state;
				resolve();
			}
			if (controlledByMine()) { finish('controlled'); return; }
			sw.addEventListener('controllerchange', function () { if (controlledByMine()) finish('claimed'); });
			setTimeout(function () { finish('timeout'); }, WAIT_MS);
			sw.register(SW).then(function (reg) {
				// Already active but not controlling this page (hard reload): ask it to claim the page.
				if (isEngineWorker(reg.active)) {
					reg.active.postMessage({ type: 'astro-engine-claim' });
				}
			}, function () { finish('register-failed'); });
		}); });
		sw.addEventListener('message', function (ev) {
			if (ev.data && ev.data.type === 'astro-engine-mismatch') info.mismatch = ev.data;
		});
	} else {
		info.state = 'unsupported';
		ready = pre;
	}

	function notice(text) {
		try {
			var s = document.getElementById('status');
			var n = document.getElementById('status-notice');
			if (!s || !n) return;
			n.textContent = text;
			n.style.display = 'block';
			s.style.visibility = 'visible';
		} catch (e) { /* page not ready */ }
	}

	// The engine stream failed (hash mismatch, or the download broke). Reload once; never boot a mix.
	function broken() {
		var key = 'astro-engine-retry-' + HASH;
		var tried = true;
		try {
			tried = sessionStorage.getItem(key) === '1';
			if (!tried) sessionStorage.setItem(key, '1');
		} catch (e) { tried = true; }
		info.state = 'broken';
		if (!tried) {
			notice('The game was updated while loading. Reloading...');
			location.reload();
		} else {
			notice('The game download did not finish or did not match this page (an update may be in progress). Please reload in a minute.');
		}
	}

	var realFetch = window.fetch;
	window.fetch = function (input, init) {
		if (input === 'index.pck') {
			// index.pck?h=<sha256 of the pck>: GitHub Pages ignores the query, but the browser's HTTP cache
			// keys on it, so within max-age=600 of a deploy the phone cannot reuse the previous build's pck
			// under the new page (measured: with plain index.pck a deploy inside that window sent 0 bytes and
			// booted the old pck), while an unchanged pck still gets its 304 / cache hit.
			return pre.then(function () { return realFetch.call(window, 'index.pck?h=' + PCK_HASH, init); });
		}
		if (input !== 'index.wasm') return realFetch.apply(this, arguments);
		var target = ENABLED ? 'index.wasm?h=' + HASH : 'index.wasm';
		return ready.then(function () {
			info.controlled = ENABLED && controlledByMine();
			return realFetch.call(window, target, init);
		}).then(function (resp) {
			info.source = resp.headers.get('X-Astro-Engine') || 'network-direct';
			if (!info.controlled || !resp.ok || !resp.body) return resp;
			var reader = resp.body.getReader();
			var body = new ReadableStream({
				pull: function (c) {
					return reader.read().then(function (r) {
						if (r.done) {
							try { sessionStorage.removeItem('astro-engine-retry-' + HASH); } catch (e) { /* ignore */ }
							info.state = 'loaded';
							c.close();
						} else {
							c.enqueue(r.value);
						}
					}, function (err) {
						broken();
						c.error(err);
					});
				},
				cancel: function (reason) { return reader.cancel(reason); },
			});
			return new Response(body, { status: resp.status, statusText: resp.statusText, headers: resp.headers });
		});
	};
}());
