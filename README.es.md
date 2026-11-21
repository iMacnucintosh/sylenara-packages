<h1 align="center">Sylenara packages</h1>

<p align="center"><a href="./README.md">English</a> · <strong>Español</strong></p>

<p align="center">
El repositorio de pacman de <a href="https://github.com/iMacnucintosh/sylenara-shell">Sylenara</a>: sus paquetes y las librerías que necesitan del AUR, ya compilados y firmados.
</p>

## Qué hay

| Paquete | Qué es |
| --- | --- |
| `sylenara-shell-git` | La shell |
| `sylenara-cli-git` | El comando `sylenara` |
| `seeker-git` | Seeker, el explorador de archivos |
| `things-git` | Things, el gestor de paquetes |
| `veo-git` | Veo, el reproductor de vídeo |
| `quickshell-git`, `qt6-m3shapes-git`, `python-materialyoucolor`, `libcava`, `ttf-rubik-vf` | Librerías sobre las que se construye la shell, del AUR |

Se compilan desde la **última release** de cada repositorio (el sufijo `-git` es solo el nombre): para repartir un cambio, saca una release allí.

## Instalación

El instalador de Sylenara lo configura; no tienes que hacer nada aquí. A mano, en Arch Linux:

```sh
sudo pacman-key --add sylenara.gpg
sudo pacman-key --lsign-key D99127AC7375512EF97E86982CBF92E205BD0DC9
```

y al final de `/etc/pacman.conf`:

```ini
[sylenara]
SigLevel = Required
Server = https://github.com/iMacnucintosh/sylenara-packages/releases/download/x86_64
```

Después, `sudo pacman -Syu sylenara-shell-git`. Las actualizaciones llegan con las del sistema.

## Cómo se construye

`.github/workflows/build.yml` se ejecuta cada tres horas (y a mano). En un contenedor limpio `archlinux:base-devel`, `scripts/plan.py` calcula qué cambió (una release nueva de uno de los repositorios, una versión nueva en el AUR, un Qt o Python nuevo en Arch, o una biblioteca que cambió de soname, como `sndio` para `libcava`: aquello a lo que están atados los binarios) y `scripts/build.sh` compila solo eso (si se recompila sin cambiar de versión, sube el pkgrel, `1` → `1.1`, para que pacman lo ofrezca), firma cada paquete y la base de datos, y `scripts/publish.sh` los sube a la release `x86_64` y quita las versiones viejas.

La clave de firma es «Sylenara packages» (ed25519, `D99127AC7375512EF97E86982CBF92E205BD0DC9`). Su mitad pública es `sylenara.gpg`; la privada vive solo en el secreto `SIGNING_KEY` de este repositorio y con su dueño.

## Licencia

GPL-3.0-only, ver [LICENSE](LICENSE). Copyright (C) 2026 Manuel López Mallorquín.

Esto cubre los scripts y los workflows de este repositorio. Cada paquete del repositorio se compila desde el código de su propio proyecto, en la etiqueta de versión que dice su número, y conserva la licencia de ese proyecto (el código de cada uno es público en `github.com/iMacnucintosh/<paquete>`; la receta, el `PKGBUILD`, sale del mismo repositorio y lleva su licencia). Los paquetes del AUR conservan la licencia que declaran.
