#!/usr/bin/env python3
"""Which packages need building: prints the plan as JSON and writes the new state.

  plan.py STATE_IN STATE_OUT [--all]

Each package has a fingerprint: what it is built from (the latest release tag of its repo; for the AUR, the version
in the AUR and, for a -git package, the commit its source points at) plus the versions of what its binaries are tied
to (Qt: the plugin, Seeker, Things and Veo use its private API; Python: compiled modules). A package is built when its
fingerprint changed; it runs inside the build container, so the versions are those Arch has today.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
CONF = json.loads((HERE / "packages.json").read_text())
OWNER = "iMacnucintosh"
UA = {"User-Agent": "sylphrena-packages"}


def get(url: str) -> str:
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
        return r.read().decode()


def latest_tag(repo: str) -> str:
    """The latest release, from the redirect of /releases/latest (no API rate limit)."""
    req = urllib.request.Request(f"https://github.com/{OWNER}/{repo}/releases/latest", headers=UA, method="HEAD")
    with urllib.request.urlopen(req, timeout=30) as r:
        url = r.geturl()
    m = re.search(r"/releases/tag/([^/?#]+)$", url)
    if not m:
        raise RuntimeError(f"{repo}: no release")
    return m.group(1)


def aur_fingerprint(name: str) -> str:
    info = json.loads(get(f"https://aur.archlinux.org/rpc/v5/info?arg[]={name}"))["results"]
    if not info:
        raise RuntimeError(f"{name}: not in the AUR")
    fp = info[0]["Version"]
    if name.endswith("-git"):
        # The version in the AUR is only updated now and then: the commit of its source is what changes
        srcinfo = get(f"https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h={name}")
        m = re.search(r"^\s*source = (?:[^:]+::)?git\+([^#\s]+)(?:#branch=(\S+))?", srcinfo, re.M)
        if m:
            ref = f"refs/heads/{m.group(2)}" if m.group(2) else "HEAD"
            out = subprocess.run(["git", "ls-remote", m.group(1), ref], capture_output=True, text=True, timeout=60).stdout
            fp += "@" + (out.split() or ["?"])[0][:12]
    return fp


def abi(kind: str) -> str:
    pkg = {"qt": "qt6-base", "python": "python"}[kind]
    out = subprocess.run(["pacman", "-Si", pkg], capture_output=True, text=True, env={"LC_ALL": "C"}).stdout
    m = re.search(r"^Version\s*:\s*(\S+)", out, re.M)
    # Without the pkgrel: a rebuild of Qt itself does not change what we link against
    return f"{kind}={m.group(1).rsplit('-', 1)[0] if m else '?'}"


def main() -> int:
    state_in, state_out = Path(sys.argv[1]), Path(sys.argv[2])
    rebuild_all = "--all" in sys.argv
    old = json.loads(state_in.read_text()) if state_in.is_file() else {}
    new, plan = {}, []
    for p in CONF["packages"]:
        if p.get("aur"):
            source = aur_fingerprint(p["name"])
            ref = ""
        else:
            ref = latest_tag(p["github"])
            source = ref
        fp = " ".join([source, *(abi(k) for k in p.get("abi", []))])
        new[p["name"]] = fp
        if rebuild_all or old.get(p["name"]) != fp:
            plan.append({**p, "ref": ref, "fingerprint": fp, "was": old.get(p["name"], "")})
    state_out.write_text(json.dumps(new, indent=2) + "\n")
    print(json.dumps(plan))
    return 0


if __name__ == "__main__":
    sys.exit(main())
