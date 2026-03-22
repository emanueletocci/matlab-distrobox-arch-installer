# MATLAB on Arch via Distrobox

A Bash script to install MATLAB on **Arch Linux** using **Distrobox** and an Ubuntu container.

## What it does

- Installs required host dependencies.
- Creates a Distrobox container.
- Installs MATLAB via **MPM** inside the container.
- Exports a `matlab` launcher to the host.
- Creates a desktop entry for the application menu.

## Requirements

- Arch Linux
- Internet connection
- `sudo` privileges
- A valid MATLAB license

## Usage

```bash
git clone https://github.com/your-username/matlab-distrobox-arch-installer.git
cd matlab-distrobox-arch-installer
chmod +x scripts/install-matlab-distrobox-arch.sh
./scripts/install-matlab-distrobox-arch.sh
```

## Result

After installation, you should have:

- a dedicated MATLAB container;
- a host-side `matlab` command;
- a desktop launcher entry.

## Fish

If you use fish on the host:

```fish
alias --save matlab 'env QT_QPA_PLATFORM=xcb $HOME/.local/bin/matlab'
```

## Notes

- The script is intended for **Arch Linux hosts**.
- MATLAB activation may still require manual login or license steps.
- On Wayland, MATLAB may need:

```bash
QT_QPA_PLATFORM=xcb matlab
```

## Disclaimer

This repository does not distribute MATLAB. It only automates setup and installation using official tools.