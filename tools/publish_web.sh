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
