#!/bin/zsh
# Export the web build and commit it to the gh-pages branch, which GitHub Pages serves at
# https://<user>.github.io/<repo>/ . Never touches the working tree or the main branch: the
# commit is assembled with a temporary index, so nothing here can clobber uncommitted work.
#
#   tools/publish_web.sh          export, then update gh-pages
#   tools/publish_web.sh --push   also push main and gh-pages to origin
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/../../build/web"
cd "$REPO"

echo "exporting..."
rm -rf "$OUT"; mkdir -p "$OUT"
godot --headless --path . --export-release "Web"
printf '' > "$OUT/.nojekyll"   # stop GitHub Pages running Jekyll over the export

BASE="$(git rev-parse --short HEAD)"

# --- Kill the service worker that PWA builds left registered on real devices -------------------
# Builds published before 2026-09-06 21:00 shipped Godot's PWA service worker. It caches
# index.pck and index.wasm CACHE-FIRST WITH NO REVALIDATION, so once a phone loaded the site it
# served that copy of the whole game forever. Disabling the PWA option only stopped NEW visitors
# from registering it; every device that already had it stayed frozen on the old build, which is
# why three rounds of fixes appeared on desktop and never on the phone.
#
# Deleting the file does not help: a 404 on the worker script fails the update check, and the
# existing registration keeps serving its cache. The only reliable removal is to publish a worker
# at the SAME URL that unregisters itself, so keep this file here permanently. Its bytes must stay
# CONSTANT - the browser compares them to decide whether to install, and a per-build stamp would
# make every device reinstall the killer forever.
cat > "$OUT/index.service.worker.js" <<'KILLSW'
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
KILLSW

# Stamp the build into index.html so "is the page stale?" is one curl, not a guess:
#   curl -s <url> | grep astro-build
python3 - "$OUT/index.html" "$BASE" <<'STAMP'
import io, sys
path, base = sys.argv[1], sys.argv[2]
html = io.open(path, encoding="utf-8").read()
tag = '<meta name="astro-build" content="%s">' % base
html = html.replace("<head>", "<head>\n\t" + tag, 1)
io.open(path, "w", encoding="utf-8").write(html)
STAMP
export GIT_INDEX_FILE="$(mktemp -t ghpages-index)"
rm -f "$GIT_INDEX_FILE"
git --work-tree="$OUT" add -A -f .
TREE="$(git write-tree)"
# zsh does NOT word-split an unquoted variable the way bash does, so the parent has to be an
# array or `git commit-tree` receives "-p <sha>" as a single argument and rejects it.
parent_args=()
if git show-ref --verify --quiet refs/heads/gh-pages; then
	parent_args=(-p "$(git rev-parse refs/heads/gh-pages)")
fi
COMMIT="$(git commit-tree "$TREE" "${parent_args[@]}" -m "Publish the playable web build

Built from $BASE.")"
git update-ref refs/heads/gh-pages "$COMMIT"
unset GIT_INDEX_FILE
echo "gh-pages updated -> $COMMIT"

if [ "${1:-}" = "--push" ]; then
	git push origin main gh-pages
	echo "pushed."
else
	echo "not pushed. run: git push origin main gh-pages"
fi
