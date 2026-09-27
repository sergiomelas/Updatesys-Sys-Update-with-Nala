#!/bin/bash
# updatesys-launcher
##################################################################
#                     Pretty System Update                       #
#                Developed by sergio melas  2021-26              #
##################################################################

SCRIPT_PATH="/usr/share/updatesys/UpdateSys.sh"

# Ensure target script exists and has execution permissions
if [ ! -x "$SCRIPT_PATH" ]; then
    chmod +x "$SCRIPT_PATH" 2>/dev/null
fi

COLS=84
ROWS=80

# Detect Terminal and Launch with updated modern CLI syntax
if command -v konsole >/dev/null 2>&1; then
    # Modern Konsole (Qt6 / KDE Plasma 6)
    exec konsole -p TerminalColumns=$COLS -p TerminalRows=$ROWS -e /bin/bash "$SCRIPT_PATH"
elif command -v foot >/dev/null 2>&1; then
    # Foot (Wayland fast native terminal)
    exec foot --window-size-chars=${COLS}x${ROWS} /bin/bash "$SCRIPT_PATH"
elif command -v ghostty >/dev/null 2>&1; then
    # Ghostty (GPU terminal)
    exec ghostty --window-width=$COLS --window-height=$ROWS -e /bin/bash "$SCRIPT_PATH"
elif command -v alacritty >/dev/null 2>&1; then
    # Modern Alacritty CLI flags (v0.12+)
    exec alacritty --option "window.dimensions.columns=$COLS" --option "window.dimensions.lines=$ROWS" -e /bin/bash "$SCRIPT_PATH"
elif command -v kitty >/dev/null 2>&1; then
    # Kitty terminal
    exec kitty -o initial_window_width=${COLS}c -o initial_window_height=${ROWS}c /bin/bash "$SCRIPT_PATH"
elif command -v gnome-terminal >/dev/null 2>&1; then
    # GNOME Terminal (GTK modern delimiter syntax)
    exec gnome-terminal --geometry=${COLS}x${ROWS} -- /bin/bash "$SCRIPT_PATH"
elif command -v xfce4-terminal >/dev/null 2>&1; then
    # XFCE4 Terminal
    exec xfce4-terminal --geometry=${COLS}x${ROWS} -x /bin/bash "$SCRIPT_PATH"
elif command -v tilix >/dev/null 2>&1; then
    # Tilix
    exec tilix --geometry=${COLS}x${ROWS} -e /bin/bash "$SCRIPT_PATH"
elif command -v terminator >/dev/null 2>&1; then
    # Terminator
    exec terminator --geometry=${COLS}x${ROWS} -x /bin/bash "$SCRIPT_PATH"
else
    # Fallback X11 terminal
    exec xterm -geometry ${COLS}x${ROWS} -e /bin/bash "$SCRIPT_PATH"
fi
