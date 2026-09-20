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

# Detect Terminal and Launch (Passing bash explicitly to prevent execve parsing errors)
if command -v konsole >/dev/null 2>&1; then
    konsole --geometry 900x1200 -e /bin/bash "$SCRIPT_PATH"
elif command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal --geometry=110x60 -- /bin/bash "$SCRIPT_PATH"
elif command -v xfce4-terminal >/dev/null 2>&1; then
    xfce4-terminal --geometry=110x60 -e "/bin/bash $SCRIPT_PATH"
elif command -v alacritty >/dev/null 2>&1; then
    alacritty -o "window.dimensions={columns=110,lines=60}" -e /bin/bash "$SCRIPT_PATH"
elif command -v kitty >/dev/null 2>&1; then
    kitty -o initial_window_width=110c -o initial_window_height=60c /bin/bash "$SCRIPT_PATH"
elif command -v tilix >/dev/null 2>&1; then
    tilix --geometry=110x60 -e "/bin/bash $SCRIPT_PATH"
elif command -v terminator >/dev/null 2>&1; then
    terminator --geometry=110x60 -e "/bin/bash $SCRIPT_PATH"
else
    xterm -geometry 110x60 -e /bin/bash "$SCRIPT_PATH"
fi
