#!/usr/bin/env bash
# ==============================================================================
# UpdateSys - Native Debian Script Builder
# Developed by Sergio Melas - 2026
# Builds deb directly into script directory (No install, pure build)
# ==============================================================================
set -euo pipefail

PACKAGE_NAME="updatesys"
PACKAGE_VERSION="1.4.2"
PACKAGE_ARCH="all"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="${BASE_DIR}/Payload"
PKG_ROOT="${BASE_DIR}/pkg_root"
DEB_FILE="${BASE_DIR}/${PACKAGE_NAME}_${PACKAGE_VERSION}_${PACKAGE_ARCH}.deb"

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #              UpdateSys - Native Debian Builder                 #"
echo " #               Version: ${PACKAGE_VERSION} - Script Packaging             #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# --- 1. Detect Payload Directory ---
if [ ! -d "${PAYLOAD_DIR}" ]; then
    echo "❌ Error: Payload directory not found at: ${PAYLOAD_DIR}" >&2
    exit 1
fi
echo "📁 Detected Payload folder at: ${PAYLOAD_DIR}"

# --- 2. Prepare Packaging Directory Structure ---
echo "🧹 Setting up staging environment..."
rm -rf "${PKG_ROOT}"
mkdir -p "${PKG_ROOT}/DEBIAN"
mkdir -p "${PKG_ROOT}/usr/share/updatesys"
mkdir -p "${PKG_ROOT}/usr/local/bin"
mkdir -p "${PKG_ROOT}/usr/share/applications"
mkdir -p "${PKG_ROOT}/usr/share/pixmaps"

# --- 3. Copy Assets from Payload ---
echo "📋 Copying Payload files to Debian filesystem hierarchy..."

# Core script to /usr/share/updatesys/UpdateSys.sh
if [ -f "${PAYLOAD_DIR}/UpdateSys.sh" ]; then
    cp "${PAYLOAD_DIR}/UpdateSys.sh" "${PKG_ROOT}/usr/share/updatesys/UpdateSys.sh"
    chmod 755 "${PKG_ROOT}/usr/share/updatesys/UpdateSys.sh"
    echo "  ✔ /usr/share/updatesys/UpdateSys.sh"
else
    echo "❌ Missing UpdateSys.sh in Payload!" >&2
    exit 1
fi

# Launcher script to /usr/local/bin/updatesys
if [ -f "${PAYLOAD_DIR}/UpdateSys_Laucher.sh" ]; then
    cp "${PAYLOAD_DIR}/UpdateSys_Laucher.sh" "${PKG_ROOT}/usr/local/bin/updatesys"
    chmod 755 "${PKG_ROOT}/usr/local/bin/updatesys"
    echo "  ✔ /usr/local/bin/updatesys"
elif [ -f "${PAYLOAD_DIR}/UpdateSys_Laucher_2.sh" ]; then
    cp "${PAYLOAD_DIR}/UpdateSys_Laucher_2.sh" "${PKG_ROOT}/usr/local/bin/updatesys"
    chmod 755 "${PKG_ROOT}/usr/local/bin/updatesys"
    echo "  ✔ /usr/local/bin/updatesys"
fi

# Desktop launcher entry
if [ -f "${PAYLOAD_DIR}/Sys Update.desktop" ]; then
    cp "${PAYLOAD_DIR}/Sys Update.desktop" "${PKG_ROOT}/usr/share/applications/updatesys.desktop"
    chmod 644 "${PKG_ROOT}/usr/share/applications/updatesys.desktop"
    echo "  ✔ /usr/share/applications/updatesys.desktop"
fi

# Application icon
if [ -f "${PAYLOAD_DIR}/updatesys.png" ]; then
    cp "${PAYLOAD_DIR}/updatesys.png" "${PKG_ROOT}/usr/share/pixmaps/updatesys.png"
    chmod 644 "${PKG_ROOT}/usr/share/pixmaps/updatesys.png"
    echo "  ✔ /usr/share/pixmaps/updatesys.png"
fi

# --- 4. Generate Control File ---
echo "📝 Writing DEBIAN/control..."
cat <<EOF > "${PKG_ROOT}/DEBIAN/control"
Package: ${PACKAGE_NAME}
Version: ${PACKAGE_VERSION}
Section: admin
Priority: optional
Architecture: ${PACKAGE_ARCH}
Depends: bash (>= 5.0), nala, coreutils
Maintainer: Sergio Melas <sergiomelas@gmail.com>
Description: Pretty System Update - Sid Specialized Maintenance Tool
 Intelligent dual-stage risk detection, transition analysis, and system cleanup.
EOF

# --- 5. Build Debian Package Directly in BASE_DIR ---
echo "📦 Packaging with dpkg-deb..."
dpkg-deb --build --root-owner-group "${PKG_ROOT}" "${DEB_FILE}"

# Cleanup staging area
rm -rf "${PKG_ROOT}"

echo " "
echo "################################################"
echo "# Built successfully!                          #"
echo "# Output: ${DEB_FILE}"
echo "################################################"
echo " "
