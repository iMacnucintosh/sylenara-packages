<h1 align="center">Sylenara packages</h1>

<p align="center"><strong>English</strong> · <a href="./README.es.md">Español</a></p>

<p align="center">
The pacman repository of <a href="https://github.com/iMacnucintosh/sylenara-shell">Sylenara</a>: its packages and the libraries they need from the AUR, ready-built and signed.
</p>

## What is in it

| Package | What it is |
| --- | --- |
| `sylenara-shell-git` | The shell itself |
| `sylenara-cli-git` | The `sylenara` command |
| `seeker-git` | Seeker, the file manager |
| `things-git` | Things, the package manager |
| `veo-git` | Veo, the video player |
| `quickshell-git`, `qt6-m3shapes-git`, `python-materialyoucolor`, `libcava`, `ttf-rubik-vf` | Libraries the shell builds on, from the AUR |

They are built from the **latest release** of each repository (the `-git` suffix is only the name): to ship a change, make a release there.

## Install

The Sylenara installer sets it up; you do not need to do anything here. By hand, on Arch Linux:

```sh
sudo pacman-key --add sylenara.gpg
sudo pacman-key --lsign-key D99127AC7375512EF97E86982CBF92E205BD0DC9
```

and at the end of `/etc/pacman.conf`:

```ini
[sylenara]
SigLevel = Required
Server = https://github.com/iMacnucintosh/sylenara-packages/releases/download/x86_64
```

Then `sudo pacman -Syu sylenara-shell-git`. Updates arrive with the system's.

## How it is built

`.github/workflows/build.yml` runs every three hours (and by hand). In a clean `archlinux:base-devel` container, `scripts/plan.py` works out what changed (a new release of one of the repositories, a new version in the AUR, a new Qt or Python in Arch, or a library whose soname changed, such as `sndio` for `libcava`: what the binaries are tied to) and `scripts/build.sh` builds only that (a rebuild that keeps the version gets a higher pkgrel, `1` → `1.1`, so pacman offers it), signs each package and the database, and `scripts/publish.sh` uploads them to the `x86_64` release and removes the old versions.

The signing key is "Sylenara packages" (ed25519, `D99127AC7375512EF97E86982CBF92E205BD0DC9`). Its public half is `sylenara.gpg`; its secret half lives only in this repository's `SIGNING_KEY` secret and with its owner.

## License

GPL-3.0-only, see [LICENSE](LICENSE). Copyright (C) 2026 Manuel López Mallorquín.

That covers the scripts and workflows of this repository. Every package in the repository is built from the source of its own project, at the release tag its version names, and keeps that project's license (the source of each one is public at `github.com/iMacnucintosh/<package>`; the build recipe, the `PKGBUILD`, comes from the same repository and is licensed with it). The packages taken from the AUR keep the license they declare.
