#!/bin/bash
# Builds the packages of a plan inside an Arch container (as root; makepkg runs as the user "builder"), signs them and
# adds them to the repository database.
#
#   SIGNING_KEY=<armored secret key> build.sh PLAN.json REPO_DIR
#
# REPO_DIR has the current database (sylenara.db, sylenara.files, as published) or nothing on the first run; the new
# packages, their signatures and the updated, signed database end up there. Packages not in the plan come from the
# published repository, so a build only needs what changed.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAN="$(realpath "$1")"
OUT="$(realpath "$2")"
CONF="$HERE/packages.json"
NAME="$(jq -r .repo "$CONF")"
KEY="$(jq -r .key "$CONF")"
SERVER="https://github.com/iMacnucintosh/sylenara-packages/releases/download/$(jq -r .release "$CONF")"
: "${SIGNING_KEY:?the secret signing key goes in SIGNING_KEY}"

echo "::group::Container"
pacman -Syu --noconfirm --needed git sudo jq python >/dev/null
id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
# Release builds, without -debug packages, using every core
cat > /etc/makepkg.conf.d/sylenara.conf <<EOF
OPTIONS+=(!debug)
MAKEFLAGS="-j$(nproc)"
PACKAGER="Sylenara packages <https://github.com/iMacnucintosh/sylenara-packages>"
GPGKEY="$KEY"
EOF
# The key signs as the builder; pacman trusts it for the packages already published
sudo -u builder gpg --batch --quiet --import <<< "$SIGNING_KEY"
pacman-key --init >/dev/null 2>&1
pacman-key --add "$HERE/sylenara.gpg" >/dev/null 2>&1
pacman-key --lsign-key "$KEY" >/dev/null 2>&1
if [[ -f "$OUT/$NAME.db" ]]; then
    printf '\n[%s]\nSigLevel = Required\nServer = %s\n' "$NAME" "$SERVER" >> /etc/pacman.conf
    pacman -Sy --noconfirm >/dev/null
fi
echo "::endgroup::"

# A rebuild that keeps the version (a library it links changed its soname, a new Qt) must still be newer than the
# published package, or pacman never offers it: same pkgver, pkgrel 1 -> 1.1 -> 1.2… (an AUR pkgrel 2 is above them).
bump_pkgrel() {
    local name="$1" dir="$2" published built rel
    published="$(LC_ALL=C pacman -Si "$NAME/$name" 2>/dev/null | sed -n 's/^Version *: *//p')"
    [[ -n "$published" ]] || return 0
    built="$(cd "$dir" && sudo -u builder env SYLENARA_REF="${3:-}" makepkg --printsrcinfo | awk -F' = ' '
        $1 ~ /^\tepoch$/ {e = $2 ":"} $1 ~ /^\tpkgver$/ {v = $2} $1 ~ /^\tpkgrel$/ {r = $2} END {print e v "-" r}')"
    (($(vercmp "$built" "$published") > 0)) && return 0
    [[ "${built%-*}" == "${published%-*}" ]] || return 0 # an older pkgver than published: leave it
    rel="${published##*-}"
    if [[ "$rel" == *.* ]]; then rel="${rel%%.*}.$((${rel#*.} + 1))"; else rel="$rel.1"; fi
    sed -i "s/^pkgrel=.*/pkgrel=$rel/" "$dir/PKGBUILD"
    echo "$name: $published is published, built as ${built%-*}-$rel"
}

work=/home/builder/build
mkdir -p "$work" && chown builder: "$work"
built=()
while read -r pkg; do
    name="$(jq -r .name <<< "$pkg")"
    echo "::group::$name ($(jq -r .fingerprint <<< "$pkg"))"
    dir="$work/$name"
    rm -rf "$dir"
    if [[ "$(jq -r '.aur // false' <<< "$pkg")" == true ]]; then
        sudo -u builder git clone --quiet --depth 1 "https://aur.archlinux.org/$name.git" "$dir"
        sub="$dir"
        ref=""
    else
        ref="$(jq -r .ref <<< "$pkg")"
        sudo -u builder git clone --quiet --depth 1 --branch "$ref" \
            "https://github.com/iMacnucintosh/$(jq -r .github <<< "$pkg").git" "$dir"
        sub="$dir/packaging"
    fi
    # Fetch and prepare first: a -git package works out its version there
    (cd "$sub" && sudo -u builder env SYLENARA_REF="$ref" makepkg --syncdeps --nobuild --noconfirm --needed)
    bump_pkgrel "$name" "$sub" "$ref"
    # -i: installed, so the packages built after it find it
    (cd "$sub" && sudo -u builder env SYLENARA_REF="$ref" makepkg --syncdeps --noextract --install --sign --noconfirm --needed)
    for f in "$sub"/*.pkg.tar.zst; do
        cp "$f" "$f.sig" "$OUT/"
        built+=("$OUT/$(basename "$f")")
    done
    echo "::endgroup::"
done < <(jq -c '.[]' "$PLAN")

if ((${#built[@]})); then
    echo "::group::Database"
    chown -R builder: "$OUT"
    cd "$OUT"
    # Published as plain files: GitHub has no symlinks
    [[ -f "$NAME.db" ]] && mv "$NAME.db" "$NAME.db.tar.gz"
    [[ -f "$NAME.files" ]] && mv "$NAME.files" "$NAME.files.tar.gz"
    rm -f "$NAME.db.sig" "$NAME.files.sig"
    sudo -u builder repo-add --sign --key "$KEY" --remove "$NAME.db.tar.gz" "${built[@]}"
    for f in db files; do
        rm -f "$NAME.$f" "$NAME.$f.sig"
        cp "$NAME.$f.tar.gz" "$NAME.$f"
        cp "$NAME.$f.tar.gz.sig" "$NAME.$f.sig"
    done
    echo "::endgroup::"
fi
