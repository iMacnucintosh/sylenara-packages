<h1 align="center">Lunele packages</h1>

<p align="center"><a href="./README.md">English</a> · <strong>Español</strong></p>

<p align="center">
El repositorio de pacman de <a href="https://github.com/iMacnucintosh/lunele-shell">Lunele</a>: sus paquetes y las librerías que necesitan del AUR, ya compilados y firmados.
</p>

## Qué hay

| Paquete | Qué es |
| --- | --- |
| `lunele-shell-git` | La shell |
| `lunele-cli-git` | El comando `lunele` |
| `seeker-git` | Seeker, el explorador de archivos |
| `things-git` | Things, el gestor de paquetes |
| `veo-git` | Veo, el reproductor de vídeo |
| `quickshell-git`, `qt6-m3shapes-git`, `python-materialyoucolor`, `libcava`, `ttf-rubik-vf` | Librerías sobre las que se construye la shell, del AUR |

Se compilan desde la **última release** de cada repositorio (el sufijo `-git` es solo el nombre): para repartir un cambio, saca una release allí.

## Instalación

El instalador de Lunele lo configura; no tienes que hacer nada aquí. A mano, en Arch Linux:

```sh
sudo pacman-key --add lunele.gpg
sudo pacman-key --lsign-key D48895A048042C67AB45D200903338E0D2D31CEC
```

y al final de `/etc/pacman.conf`:

```ini
[lunele]
SigLevel = Required
Server = https://github.com/iMacnucintosh/lunele-packages/releases/download/x86_64
```

Después, `sudo pacman -Syu lunele-shell-git`. Las actualizaciones llegan con las del sistema.

## Cómo se construye

`.github/workflows/build.yml` se ejecuta cada tres horas (y a mano). En un contenedor limpio `archlinux:base-devel`, `scripts/plan.py` calcula qué cambió (una release nueva de uno de los repositorios, una versión nueva en el AUR, o un Qt o Python nuevo en Arch, a los que están atados los binarios) y `scripts/build.py` compila solo eso, firma cada paquete y la base de datos, y `scripts/publish.sh` los sube a la release `x86_64` y quita las versiones viejas.

La clave de firma es «Lunele packages» (ed25519, `D48895A048042C67AB45D200903338E0D2D31CEC`). Su mitad pública es `lunele.gpg`; la privada vive solo en el secreto `SIGNING_KEY` de este repositorio y con su dueño.
