#!/bin/bash
#Clean Debian Builder
# Developed by Sergio Melas - 2026



# --- Configuration ---
PKG_NAME="updatesys"
PKG_VER="1.0"
# Detect the folder where this script is located (SRC)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Target the subfolder where the actual files are
PAYLOAD_DIR="${BASE_DIR}/Payload"
BUILD_DIR="${BASE_DIR}/build_workspace"

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #            System Configuration Debia                          #"
echo " #          Master Builder V1.0 - Debian Integration              #"
echo " #                                                                #"
echo " ##################################################################"
echo " "


# --- Exact Filenames from your Payload folder ---
MAIN_LOGIC="UpdateSys.sh"
LAUNCHER="UpdateSys_Laucher.sh"
DESKTOP_FILE="Sys Update.desktop"
ICON_FILE="updatesys.png"

echo "🚀 Starting UpdateSys V${PKG_VER} Payload-Aware Build..."

# --- Pre-Build Verification ---
# This checks specifically inside the Payload subfolder
if [ ! -d "$PAYLOAD_DIR" ]; then
    echo "❌ ERROR: Subfolder 'Payload' not found in: ${BASE_DIR}"
    exit 1
fi

for file in "$MAIN_LOGIC" "$LAUNCHER" "$DESKTOP_FILE" "$ICON_FILE"; do
    if [ ! -f "${PAYLOAD_DIR}/$file" ]; then
        echo "❌ ERROR: File '$file' was not found in: ${PAYLOAD_DIR}"
        exit 1
    fi
done

# 1. Clean and create structure
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/updatesys"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/pixmaps"

# 2. Copy files from Payload to system paths
cp "${PAYLOAD_DIR}/$MAIN_LOGIC" "$BUILD_DIR/usr/share/updatesys/UpdateSys.sh"
cp "${PAYLOAD_DIR}/$LAUNCHER" "$BUILD_DIR/usr/bin/updatesys"
cp "${PAYLOAD_DIR}/$DESKTOP_FILE" "$BUILD_DIR/usr/share/applications/updatesys.desktop"
cp "${PAYLOAD_DIR}/$ICON_FILE" "$BUILD_DIR/usr/share/pixmaps/updatesys.png"

chmod +x "$BUILD_DIR/usr/share/updatesys/UpdateSys.sh"
chmod +x "$BUILD_DIR/usr/bin/updatesys"

# 3. Create the Debian Control File
cat <<EOF > "$BUILD_DIR/DEBIAN/control"
Package: $PKG_NAME
Version: $PKG_VER
Section: utils
Priority: optional
Architecture: all
Maintainer: Sergio Melas <sergiomelas@gmail.com>
Depends: nala, fastfetch, flatpak, bash
Recommends: konsole | gnome-terminal | xfce4-terminal
Description: Pretty System Update
 Professional system updater for Debian. Standardized Payload build.
EOF

# --- Dynamic Padding Logic for the Installer Box ---
WIDTH=48
STR1="# UpdateSys V${PKG_VER} installed successfully."
PAD1=$(( WIDTH - ${#STR1} - 1 ))
LINE1="${STR1}$(printf '%*s' $PAD1 '')#"
STR2="# You can run it by typing 'updatesys'"
PAD2=$(( WIDTH - ${#STR2} - 1 ))
LINE2="${STR2}$(printf '%*s' $PAD2 '')#"
STR3="# or find it in your application menu."
PAD3=$(( WIDTH - ${#STR3} - 1 ))
LINE3="${STR3}$(printf '%*s' $PAD3 '')#"

# 4. Post-Installation Script
cat <<EOF > "$BUILD_DIR/DEBIAN/postinst"
#!/bin/bash
update-desktop-database /usr/share/applications >/dev/null 2>&1

# Refresh KDE Plasma cache
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1
elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 --noincremental >/dev/null 2>&1
fi

echo "################################################"
echo "$LINE1"
echo "$LINE2"
echo "$LINE3"
echo "################################################"
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# 5. Post-Removal Script
cat <<EOF > "$BUILD_DIR/DEBIAN/postrm"
#!/bin/bash
if [ "\$1" = "remove" ]; then
    rm -rf /usr/share/updatesys
    rm -f /usr/share/pixmaps/updatesys.png
    update-desktop-database /usr/share/applications >/dev/null 2>&1
fi
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postrm"

# 6. Build the final .deb package
echo "🏗️  Compiling .deb package..."
dpkg-deb --build "$BUILD_DIR" "${BASE_DIR}/${PKG_NAME}_${PKG_VER}_all.deb"

# Cleanup
rm -rf "$BUILD_DIR"
echo "✅ Build successful! Find your file in: ${BASE_DIR}"
