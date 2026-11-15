# Sylphrena packages

The pacman repository of [Sylphrena](https://github.com/iMacnucintosh/sylphrena-shell): its five packages (the shell,
sylphrena-cli, Seeker, Things and Veo) and the libraries they need from the AUR, ready-built and signed.

The Sylphrena installer sets it up; you do not need to do anything here. By hand, it is:

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

## How it is built

`.github/workflows/build.yml` runs every three hours (and by hand). In a clean `archlinux:base-devel` container,
`scripts/plan.py` works out what changed — a new release of one of the repositories, a new version in the AUR, or a
new Qt or Python in Arch, which the binaries are tied to — and `scripts/build.sh` builds only that, signs each package
and the database, and `scripts/publish.sh` uploads them to the `x86_64` release and removes the old versions.

Packages are built from the **latest release** of each repository: to ship a change, make a release there.

The signing key is "Sylphrena packages" (ed25519, `D48895A048042C67AB45D200903338E0D2D31CEC`); its public half is
`sylphrena.gpg`, its secret half lives only in the `SIGNING_KEY` secret of this repository and with its owner.
