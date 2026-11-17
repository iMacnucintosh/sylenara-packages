#!/bin/bash
# Publishes REPO_DIR to the release that serves the repository: the new packages and signatures, the database and the
# state, then removes the packages the database no longer lists (old versions).
#
#   GH_TOKEN=… publish.sh REPO_DIR STATE.json
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(realpath "$1")"
STATE="$(realpath "$2")"
NAME="$(jq -r .repo "$HERE/packages.json")"
TAG="$(jq -r .release "$HERE/packages.json")"
REPO="iMacnucintosh/lunele-packages"

cd "$OUT"
files=(./*.pkg.tar.zst ./*.pkg.tar.zst.sig)
[[ -e "${files[0]}" ]] || files=()
# The packages first and the database last: a client never sees a database that lists a package not there yet
if ((${#files[@]})); then
    gh release upload "$TAG" "${files[@]}" --repo "$REPO" --clobber
    gh release upload "$TAG" "$NAME.db" "$NAME.db.sig" "$NAME.files" "$NAME.files.sig" --repo "$REPO" --clobber
fi
cp "$STATE" ./state.json
gh release upload "$TAG" state.json --repo "$REPO" --clobber

# What the database lists, and what has to stay besides
keep="$(tar -xOf "$NAME.db" --wildcards '*/desc' | awk '/^%FILENAME%$/{getline; print; print $0 ".sig"}')"
keep+=$'\n'"$NAME.db"$'\n'"$NAME.db.sig"$'\n'"$NAME.files"$'\n'"$NAME.files.sig"$'\n'"state.json"
gh release view "$TAG" --repo "$REPO" --json assets --jq '.assets[].name' | while read -r asset; do
    if ! grep -qxF "$asset" <<< "$keep"; then
        echo "removing $asset"
        gh release delete-asset "$TAG" "$asset" --repo "$REPO" --yes
    fi
done
