#!/bin/bash
# updatesys-launcher
##################################################################
#                     Pretty System Update                       #
#                Developed by sergio melas  2021-26              #
##################################################################

SCRIPT_PATH="/usr/share/updatesys/UpdateSys.sh"

# Detect Terminal and Launch
if command -v konsole >/dev/null 2>&1; then
    konsole --geometry 900x600 --separate -e /bin/bash -c "$SCRIPT_PATH"
elif command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal --geometry=110x30 -- bash -c "$SCRIPT_PATH"
elif command -v xfce4-terminal >/dev/null 2>&1; then
    xfce4-terminal --geometry=110x30 -e "bash -c $SCRIPT_PATH"
elif command -v alacritty >/dev/null 2>&1; then
    alacritty -e bash -c "$SCRIPT_PATH"
elif command -v kitty >/dev/null 2>&1; then
    kitty bash -c "$SCRIPT_PATH"
else
    # Fallback for generic X terminals
    xterm -geometry 110x30 -e "bash -c $SCRIPT_PATH"
fi
