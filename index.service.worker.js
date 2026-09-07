// Self-destructing replacement for the PWA service worker this project used to ship.
// It takes over from the old worker, drops every cache it created, unregisters itself, and
// reloads any open tab so the reload reaches the network. Do not delete this file: it is what
// un-sticks devices that registered the old worker, and it must stay reachable at this URL.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
	event.waitUntil((async () => {
		try {
			const keys = await caches.keys();
			await Promise.all(keys.map((k) => caches.delete(k)));
		} catch (e) { /* a failed cache purge must not block the unregister below */ }
		try { await self.registration.unregister(); } catch (e) { /* already gone */ }
		try {
			const windows = await self.clients.matchAll({ type: 'window' });
			// The page in front of the user was served from the dead cache, so it has to reload.
			await Promise.all(windows.map((c) => c.navigate(c.url).catch(() => {})));
		} catch (e) { /* no controlled clients */ }
	})());
});
