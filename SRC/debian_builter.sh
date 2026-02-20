#!/bin/bash

# --- Configuration ---
PKG_NAME="updatesys"
PKG_VER="1.0"  # Change this, and the box below updates automatically!
BUILD_DIR="build_workspace"

# --- Source Files ---
MAIN_LOGIC="UpdateSys.sh"
LAUNCHER="UpdateSys_Laucher.sh"
DESKTOP_FILE="Sys Update.desktop"
ICON_FILE="updatesys.png"

echo "🚀 Starting UpdateSys V${PKG_VER} Build (Universal Edition)..."

# 1. Clean and create build structure
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/updatesys"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/icons/hicolor/scalable/apps"

# 2. Copy files to standard system paths
cp "$MAIN_LOGIC" "$BUILD_DIR/usr/share/updatesys/UpdateSys.sh"
cp "$LAUNCHER" "$BUILD_DIR/usr/bin/updatesys"
cp "$DESKTOP_FILE" "$BUILD_DIR/usr/share/applications/updatesys.desktop"
cp "$ICON_FILE" "$BUILD_DIR/usr/share/icons/hicolor/scalable/apps/updatesys.png"

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
Recommends: konsole | gnome-terminal | xfce4-terminal | xterm
Suggests: snapd
Description: Pretty System Update
 A professional Nala-inspired system updater with
 high-visibility progress bars and universal terminal support.
EOF

# --- Helper to build the perfectly padded lines ---
# This calculates how many spaces are needed to make the line exactly 48 chars wide
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
gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1
update-desktop-database /usr/share/applications >/dev/null 2>&1

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
    gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1
    update-desktop-database /usr/share/applications >/dev/null 2>&1
fi
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postrm"

# 6. Compile
echo "🏗️  Compiling .deb package..."
dpkg-deb --build "$BUILD_DIR" "${PKG_NAME}_${PKG_VER}_all.deb"

rm -rf "$BUILD_DIR"
echo "✅ Build complete: ${PKG_NAME}_${PKG_VER}_all.deb"
