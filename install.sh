#!/usr/bin/env bash

set -euo pipefail

readonly MATLAB_RELEASE="R2025b"
readonly CONTAINER_NAME="matlab-$MATLAB_RELEASE-box"
readonly IMAGE="ubuntu:22.04"
readonly MATLAB_PRODUCTS="MATLAB"
readonly MATLAB_DEST="$HOME/matlab/$MATLAB_RELEASE"
readonly HOST_EXPORT_BIN="$HOME/.local/bin"
readonly NVIDIA_SUPPORT=true

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Comando mancante: $1" >&2
        exit 1
    }
}

echo "==> Installing arch dependencies"
sudo pacman -Syu --needed --noconfirm \
distrobox podman wget unzip xorg-xhost xorg-xwayland

need_cmd podman
need_cmd distrobox

echo "==> Verifying podman rootless"
systemctl --user enable --now podman.socket >/dev/null 2>&1 || true

echo "==> Authorizing local GUI for container"
xhost +si:localuser:"$USER" >/dev/null || true

if ! distrobox-list --no-color 2>/dev/null | awk '{print $1}' | grep -qx "$CONTAINER_NAME"; then
    echo "==> Creating container $CONTAINER_NAME"
    distrobox-create --name "$CONTAINER_NAME" --image "$IMAGE" --yes
else
    echo "==> Container $CONTAINER_NAME already exists"
fi

echo "==> Configuring the container and installing MATLAB"
distrobox-enter "$CONTAINER_NAME" -- bash -lc "
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y \
  ca-certificates wget unzip libatomic1 xwayland \
  libx11-6 libxext6 libxrender1 libxtst6 libxi6 libxmu6 libxcb1 \
  libxcomposite1 libxcursor1 libxdamage1 libxfixes3 libxrandr2 \
  libasound2 libgtk2.0-0 libglib2.0-0 nano

mkdir -p \"\$HOME/.local/bin/mpm\" \"\$HOME/.local/share/applications\" \"$(dirname "$MATLAB_DEST")\"
cd \"\$HOME/.local/bin/mpm\"

wget -O mpm https://www.mathworks.com/mpm/glnxa64/mpm
chmod +x mpm
./mpm --version

./mpm install --release=${MATLAB_RELEASE} --destination=\"${MATLAB_DEST}\" --products ${MATLAB_PRODUCTS}

echo "==> Creating desktop entry and exporting host command"

cat > \"\$HOME/.local/share/applications/matlab.desktop\" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=MATLAB
Comment=Scientific computing environment
Exec=env QT_QPA_PLATFORM=xcb ${MATLAB_DEST}/bin/matlab -desktop -useStartupFolderPref
Terminal=false
Categories=Development;Math;Science;
MimeType=text/x-matlab;
StartupNotify=true
EOF

echo "==> Exporting desktop entry and host command"
distrobox-export --app \"\$HOME/.local/share/applications/matlab.desktop\" --export-label none
distrobox-export --bin \"${MATLAB_DEST}/bin/matlab\" --export-path \"${HOST_EXPORT_BIN}\" --extra-flags \"-desktop -useStartupFolderPref\"
"

echo
echo "==> Installation completed"
echo "MATLAB installed in: ${MATLAB_DEST}"
echo "Host command exported in: ${HOST_EXPORT_BIN}/matlab"
echo
echo "If you use fish on the host, save a persistent alias like this:"
echo "alias --save matlab 'env QT_QPA_PLATFORM=xcb ${HOST_EXPORT_BIN}/matlab'"
echo
echo "To activate the license for the first time:"
echo "distrobox-enter ${CONTAINER_NAME} -- env QT_QPA_PLATFORM=xcb ${MATLAB_DEST}/bin/glnxa64/MathWorksProductAuthorizer.sh"