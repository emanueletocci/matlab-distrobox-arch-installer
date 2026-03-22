#!/bin/bash

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
        echo "Missing command: $1" >&2
        exit 1
    }
}

echo "==> Installing Arch dependencies"
sudo pacman -Syu --needed --noconfirm \
distrobox \
podman \
wget \
unzip \
xorg-xhost \
xorg-xwayland

need_cmd podman
need_cmd distrobox

echo "==> Verifying Podman rootless"
systemctl --user enable --now podman.socket >/dev/null 2>&1 || true

echo "==> Authorizing local GUI for container"
xhost +si:localuser:"$USER" >/dev/null || true

if ! distrobox-list --no-color 2>/dev/null | awk '{print $1}' | grep -qx "$CONTAINER_NAME"; then
    echo "==> Creating container $CONTAINER_NAME"
    if [ "$NVIDIA_SUPPORT" = true ]; then
        distrobox-create --name "$CONTAINER_NAME" --image "$IMAGE" --nvidia --yes
    else
        distrobox-create --name "$CONTAINER_NAME" --image "$IMAGE" --yes
    fi
else
    echo "==> Container $CONTAINER_NAME already exists"
fi

echo "==> Copying container installer"
distrobox-enter "$CONTAINER_NAME" -- mkdir -p /tmp/matlab-installer
distrobox-enter "$CONTAINER_NAME" -- sh -c 'cat > /tmp/matlab-installer/install_in_container.sh' < scripts/install_in_container.sh
distrobox-enter "$CONTAINER_NAME" -- chmod +x /tmp/matlab-installer/install_in_container.sh

echo "==> Running container installer"
distrobox-enter "$CONTAINER_NAME" -- env \
MATLAB_RELEASE="$MATLAB_RELEASE" \
MATLAB_PRODUCTS="$MATLAB_PRODUCTS" \
MATLAB_DEST="$MATLAB_DEST" \
HOST_EXPORT_BIN="$HOST_EXPORT_BIN" \
/tmp/matlab-installer/install_in_container.sh

echo
echo "==> Installation completed"
echo "MATLAB installed in: $MATLAB_DEST"
echo "Host command exported in: $HOST_EXPORT_BIN/matlab"
echo
echo "If you use fish on the host, save a persistent alias like this:"
echo "alias --save matlab 'env QT_QPA_PLATFORM=xcb $HOST_EXPORT_BIN/matlab'"
echo
echo "To activate the license for the first time:"
echo "distrobox-enter $CONTAINER_NAME -- env QT_QPA_PLATFORM=xcb $MATLAB_DEST/bin/glnxa64/MathWorksProductAuthorizer.sh"