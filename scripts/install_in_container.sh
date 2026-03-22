#!/bin/bash

set -euo pipefail

: "${MATLAB_RELEASE:?MATLAB_RELEASE is required}"
: "${MATLAB_PRODUCTS:?MATLAB_PRODUCTS is required}"
: "${MATLAB_DEST:?MATLAB_DEST is required}"
: "${HOST_EXPORT_BIN:?HOST_EXPORT_BIN is required}"

echo "==> Installing container dependencies"
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y \
ca-certificates \
wget \
unzip \
libatomic1 \
xwayland \
libx11-6 \
libxext6 \
libxrender1 \
libxtst6 \
libxi6 \
libxmu6 \
libxcb1 \
libxcomposite1 \
libxcursor1 \
libxdamage1 \
libxfixes3 \
libxrandr2 \
libasound2 \
libgtk2.0-0 \
libglib2.0-0 \
nano

echo "==> Creating required directories"
mkdir -p \
"$HOME/.local/bin/mpm" \
"$HOME/.local/share/applications" \
"$(dirname "$MATLAB_DEST")"

cd "$HOME/.local/bin/mpm"

echo "==> Downloading MPM"

wget -O mpm https://www.mathworks.com/mpm/glnxa64/mpm
chmod +x mpm
./mpm --version

echo "==> Installing MATLAB"
./mpm install \
--release="$MATLAB_RELEASE" \
--destination="$MATLAB_DEST" \
--products "$MATLAB_PRODUCTS"

echo "==> Creating desktop entry"
cat > "$HOME/.local/share/applications/matlab.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=MATLAB
Comment=Scientific computing environment
Exec=env QT_QPA_PLATFORM=xcb $MATLAB_DEST/bin/matlab -desktop -useStartupFolderPref
Terminal=false
Categories=Development;Math;Science;
MimeType=text/x-matlab;
StartupNotify=true
EOF

echo "==> Exporting desktop entry and host command"
distrobox-export --app "$HOME/.local/share/applications/matlab.desktop" --export-label none
distrobox-export --bin "$MATLAB_DEST/bin/matlab" --export-path "$HOST_EXPORT_BIN" --extra-flags "-desktop -useStartupFolderPref"

echo "==> Container-side installation completed"
echo "MATLAB installed in: $MATLAB_DEST"