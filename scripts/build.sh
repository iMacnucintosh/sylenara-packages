#!/bin/bash
# Builds the packages of a plan inside an Arch container (as root; makepkg runs as the user "builder"), signs them and
# adds them to the repository database.
#
#   SIGNING_KEY=<armored secret key> build.sh PLAN.json REPO_DIR
#
# REPO_DIR has the current database (lunele.db, lunele.files, as published) or nothing on the first run; the new
# packages, their signatures and the updated, signed database end up there. Packages not in the plan come from the
# published repository, so a build only needs what changed.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAN="$(realpath "$1")"
OUT="$(realpath "$2")"
CONF="$HERE/packages.json"
NAME="$(jq -r .repo "$CONF")"
KEY="$(jq -r .key "$CONF")"
SERVER="https://github.com/iMacnucintosh/lunele-packages/releases/download/$(jq -r .release "$CONF")"
: "${SIGNING_KEY:?the secret signing key goes in SIGNING_KEY}"

echo "::group::Container"
pacman -Syu --noconfirm --needed git sudo jq python >/dev/null
id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
# Release builds, without -debug packages, using every core
cat > /etc/makepkg.conf.d/lunele.conf <<EOF
OPTIONS+=(!debug)
MAKEFLAGS="-j$(nproc)"
PACKAGER="Lunele packages <https://github.com/iMacnucintosh/lunele-packages>"
GPGKEY="$KEY"
EOF
# The key signs as the builder; pacman trusts it for the packages already published
sudo -u builder gpg --batch --quiet --import <<< "$SIGNING_KEY"
pacman-key --init >/dev/null 2>&1
pacman-key --add "$HERE/lunele.gpg" >/dev/null 2>&1
pacman-key --lsign-key "$KEY" >/dev/null 2>&1
if [[ -f "$OUT/$NAME.db" ]]; then
    printf '\n[%s]\nSigLevel = Required\nServer = %s\n' "$NAME" "$SERVER" >> /etc/pacman.conf
    pacman -Sy --noconfirm >/dev/null
fi
echo "::endgroup::"

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
    # -i: installed, so the packages built after it find it
    (cd "$sub" && sudo -u builder env LUNELE_REF="$ref" makepkg --syncdeps --install --sign --noconfirm --needed)
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
