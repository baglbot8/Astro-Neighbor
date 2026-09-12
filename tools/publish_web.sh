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

BASE="$(git rev-parse --short HEAD)"

echo "exporting..."
rm -rf "$OUT"; mkdir -p "$OUT"

# --- Stamp the build INTO the game, not just the page ------------------------------------------
# The page has carried <meta name="astro-build"> for a while (below the export); the GAME could not
# show it, so a phone report still could not prove which build was on screen without console
# access (docs/OPEN_ISSUES.md 33 - a cached service worker once froze a phone on a two-day-old
# build for three rounds of "fixes" that never reached it).
#
# A PLAIN res:// FILE DOES NOT SURVIVE THIS EXPORT - measured, not guessed: `export_filter=
# "all_resources"` only bundles files the ResourceLoader recognises (.gd/.tscn/.tres, imported
# assets). A build_stamp.txt dropped at the project root, and every tools/*.sh, tools/*.py and
# docs/*.md, were silently absent from the exported .pck (grepped for after export). Making a raw
# file survive needs an `include_filter` entry in export_presets.cfg, which is not this script's to
# edit. project.godot's settings compile into project.binary, which every export bundles regardless
# of any filter, so the stamp goes there instead - a throwaway custom setting the game reads with
# `ProjectSettings.get_setting("astro/build_stamp", "dev")` (src/ui/title/title_screen.gd).
#
# Written directly into project.godot, then restored from an exact backup - not "undone" by
# pattern-matching the appended text back out - so a crash mid-export can never leave a developer
# tree dirty.
#
# The restore has to run on INT and TERM, not just EXIT - measured, not guessed. A plain
# `trap ... EXIT` misses the ordinary way this script actually dies: SIGTERM's default
# disposition is immediate termination, and a signal with no trap of its own never runs the
# shell's EXIT trap at all - project.godot stayed stamped and project.godot.prestamp was left
# behind (sent SIGTERM to this script's own pid while it sat blocked in the foreground `godot`
# export, both on this script and in an isolated repro).
#
# Adding `trap ... TERM INT` around that same foreground `godot` call is not enough by itself -
# also measured. While the shell is blocked in a *foreground* exec, delivery of a signal it does
# have a trap for is deferred until that foreground command exits on its own, so the handler
# didn't run until the export finished anyway, and the export - now nobody's job to stop - kept
# baking the stamped project.binary regardless of the trap. Backgrounding `godot` and blocking on
# `wait` instead fixed it: `wait` on a specific job returns as soon as a trapped signal arrives,
# so the handler runs immediately and can kill the still-running export before it finishes.
GODOT_PID=""
_restore_project() {
	# Idempotent - the EXIT trap and the interrupt path can both call this.
	if [ -f project.godot.prestamp ]; then
		mv -f project.godot.prestamp project.godot
	fi
}
_on_interrupt() {
	# Clear every trap first so this can't re-enter itself, and so the `exit` below doesn't
	# also re-fire the EXIT trap.
	trap - EXIT INT TERM
	if [ -n "$GODOT_PID" ] && kill -0 "$GODOT_PID" 2>/dev/null; then
		kill -TERM "$GODOT_PID" 2>/dev/null || true
		# Give it up to 2s to exit on its own before project.godot is touched, then make sure.
		for _ in 1 2 3 4 5 6 7 8 9 10; do
			kill -0 "$GODOT_PID" 2>/dev/null || break
			sleep 0.2
		done
		kill -KILL "$GODOT_PID" 2>/dev/null || true
		wait "$GODOT_PID" 2>/dev/null || true
	fi
	_restore_project
	exit 143
}
cp project.godot project.godot.prestamp
trap _restore_project EXIT
trap _on_interrupt INT TERM
printf '\n[astro]\n\nbuild_stamp="%s"\n' "$BASE" >> project.godot
godot --headless --path . --export-release "Web" &
GODOT_PID=$!
wait "$GODOT_PID"
trap - INT TERM
_restore_project
trap - EXIT

printf '' > "$OUT/.nojekyll"   # stop GitHub Pages running Jekyll over the export

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
