<h1 align="center">Sylphrena packages</h1>

<p align="center"><strong>English</strong> · <a href="./README.es.md">Español</a></p>

<p align="center">
The pacman repository of <a href="https://github.com/iMacnucintosh/sylphrena-shell">Sylphrena</a>: its packages and the libraries they need from the AUR, ready-built and signed.
</p>

## What is in it

| Package | What it is |
| --- | --- |
| `sylphrena-shell-git` | The shell itself |
| `sylphrena-cli-git` | The `sylph` command |
| `seeker-git` | Seeker, the file manager |
| `things-git` | Things, the package manager |
| `veo-git` | Veo, the video player |
| `quickshell-git`, `qt6-m3shapes-git`, `python-materialyoucolor`, `libcava`, `ttf-rubik-vf` | Libraries the shell builds on, from the AUR |

They are built from the **latest release** of each repository (the `-git` suffix is only the name): to ship a change, make a release there.

## Install

The Sylphrena installer sets it up; you do not need to do anything here. By hand, on Arch Linux:

```sh
sudo pacman-key --add sylphrena.gpg
sudo pacman-key --lsign-key D48895A048042C67AB45D200903338E0D2D31CEC
```

and at the end of `/etc/pacman.conf`:

```ini
[sylphrena]
SigLevel = Required
Server = https://github.com/iMacnucintosh/sylphrena-packages/releases/download/x86_64
```

Then `sudo pacman -Syu sylphrena-shell-git`. Updates arrive with the system's.

## How it is built

`.github/workflows/build.yml` runs every three hours (and by hand). In a clean `archlinux:base-devel` container, `scripts/plan.py` works out what changed (a new release of one of the repositories, a new version in the AUR, or a new Qt or Python in Arch, which the binaries are tied to) and `scripts/build.py` builds only that, signs each package and the database, and `scripts/publish.sh` uploads them to the `x86_64` release and removes the old versions.

The signing key is "Sylphrena packages" (ed25519, `D48895A048042C67AB45D200903338E0D2D31CEC`). Its public half is `sylphrena.gpg`; its secret half lives only in this repository's `SIGNING_KEY` secret and with its owner.
