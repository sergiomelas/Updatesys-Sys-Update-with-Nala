#!/bin/bash

##################################################################
#              Pretty System Update - Nala Edition               #
#            Developed by sergio melas  2021-26                  #
##################################################################

# --- Colors ---
C_BORDER='\e[96m'  # Cyan
C_TEXT='\e[97m'    # White
C_BOLD='\e[1m'
C_WARN='\e[93m'    # Yellow/Gold
C_PROMPT='\e[92m'  # Green
C_NALA_G='\e[32m'  # Nala Green
C_NALA_R='\e[31m'  # Nala Red
C_RESET='\e[0m'

# --- 1. Nala-Style Progress Bar ---
draw_progress() {
    local current=$1
    local total=6
    local width=79

    local percent=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))

    # Nala Style: Green for done, Red for remaining, No background
    echo -ne "${C_NALA_G}"
    for i in $(seq 1 $filled); do echo -n "━"; done
    echo -ne "${C_NALA_R}"
    for i in $(seq 1 $empty); do echo -n "━"; done
    echo -e "${C_RESET}"

    echo -e " Progress: ${percent}% [Step ${current}/${total}]"
}

# --- 2. Header Function ---
draw_header() {
    local title="$1"
    local tip="$2"
    local width=79
    local title_len=${#title}
    local bar_len=$((width - title_len - 5))

    echo -ne "${C_BORDER}┏━${C_TEXT}${C_BOLD} ${title} ${C_RESET}${C_BORDER}"
    for i in $(seq 1 $bar_len); do echo -n "━"; done
    echo -e "┓${C_RESET}"

    echo -ne "${C_BORDER}┃"
    if [ -z "$tip" ]; then
        for i in $(seq 1 $((width - 2))); do echo -n " "; done
    else
        local tip_len=${#tip}
        local pad=$((width - tip_len - 4))
        echo -ne "${C_RESET}  ${tip}"
        for i in $(seq 1 $pad); do echo -n " "; done
    fi
    echo -e "${C_BORDER}┃${C_RESET}"

    echo -ne "${C_BORDER}┗"
    for i in $(seq 1 $((width - 2))); do echo -n "━"; done
    echo -e "┛${C_RESET}"
}

# --- 3. Startup ---
clear
draw_progress 1
draw_header "System Update" "Checking OS status"
fastfetch -l none -s os:kernel:uptime:memory

echo ""
draw_header "Administrator Login" "Rights required"
sudo ls >/dev/null

# --- 4. Silent Repo Update ---
clear
draw_progress 2
draw_header "Retrieving Updates" "Syncing repositories"
# Capture output to check for real updates
sudo nala update 2>&1 | tee /tmp/up_check.txt

# --- 5. SMART SILENT CHECK ---
echo -e "\n${C_TEXT}Performing silent update check...${C_RESET}"

APT_UP=true
# FIX: Only set to false if the number before "packages" is 1 or more
if grep -qE "[1-9][0-9]* packages can be upgraded" /tmp/up_check.txt; then
    APT_UP=false
fi

FP_UP=true
if command -v flatpak &> /dev/null; then
    if flatpak update --dry-run 2>&1 | grep -qE "ID|Installing|Updating"; then FP_UP=false; fi
fi

SNAP_UP=true
if command -v snap &> /dev/null; then
    if ! sudo snap refresh --list 2>&1 | grep -iqE "up to date|no updates"; then SNAP_UP=false; fi
fi
rm -f /tmp/up_check.txt

# --- 6. Execution Branch ---
if [ "$APT_UP" = true ] && [ "$FP_UP" = true ] && [ "$SNAP_UP" = true ]; then
    clear
    draw_progress 3
    draw_header "Status" "System is already up to date"
else
    # Only show these if there is actually something to do
    if [ "$APT_UP" = false ]; then
        echo -ne "\n${C_PROMPT}APT Updates found. Continue? [Y/n]${C_RESET} "
        read -r resp
        if [ "$resp" != "n" ] && [ "$resp" != "N" ]; then
            clear
            draw_progress 4
            draw_header "Updating System" "Applying APT patches"
            sudo nala upgrade --autoremove --install-recommends --fix-broken --purge --no-update
        fi
    fi

    if [ "$FP_UP" = false ]; then
        echo -e "\n${C_TEXT}Updating Flatpaks...${C_RESET}"
        sudo flatpak update -y
    fi

    if [ "$SNAP_UP" = false ]; then
        echo -e "\n${C_TEXT}Updating Snaps...${C_RESET}"
        sudo snap refresh
    fi
fi

#!/bin/bash

# ... [Previous Headers and Progress Bar functions remain the same] ...

# --- 7. Cleanup Section with Visibility Pauses ---
echo -ne "\n${C_PROMPT}Run system cleanup? [y/N]${C_RESET} "
read -r resp
if [ "$resp" = "y" ] || [ "$resp" = "Y" ]; then

    # --- Step 7.1: APT & Cache Cleanup ---
    clear
    draw_progress 5
    draw_header "Cleanup: APT Cache" "Removing package archives"
    sudo nala clean
    sudo apt autoclean
    echo -e "\n${C_TEXT}APT cache cleared.${C_RESET}"
    echo -ne "${C_WARN}Press any key to continue to Log cleanup...${C_RESET}"
    read -n 1 -s -r

    # --- Step 7.2: Journal/Log Cleanup ---
    clear
    draw_progress 5
    draw_header "Cleanup: System Logs" "Vacuuming Journalctl to 100M"
    sudo journalctl --vacuum-size=100M
    echo -e "\n${C_TEXT}Logs reduced to 100MB.${C_RESET}"
    echo -ne "${C_WARN}Press any key to continue to Orphan removal...${C_RESET}"
    read -n 1 -s -r

    # --- Step 7.3: Package Autoremove ---
    clear
    draw_progress 5
    draw_header "Cleanup: Orphan Packages" "Removing unused dependencies"
    sudo apt --purge autoremove -y
    echo -e "\n${C_TEXT}Unused packages removed.${C_RESET}"
    echo -ne "${C_WARN}Press any key to continue to Kernel/Config purge...${C_RESET}"
    read -n 1 -s -r

    # --- Step 7.4: Kernel Modules & Residual Configs ---
    clear
    draw_progress 5
    draw_header "Cleanup: Residual Files" "Purging old configs and kernels"
    # Purge residual config files (marked 'rc' in dpkg)
    purgestr=$(dpkg -l | grep "^rc" | awk '{print $2}')
    if [ -n "$purgestr" ]; then
        sudo dpkg --purge "$purgestr"
    else
        echo "No residual configurations found."
    fi
    echo -e "\n${C_TEXT}Residual files purged.${C_RESET}"
    echo -ne "${C_PROMPT}All cleanup phases complete. Press any key to finish...${C_RESET}"
    read -n 1 -s -r
fi

# --- 8. Final Reboot ---
clear
draw_progress 6
if [ -f /var/run/reboot-required ]; then
    draw_header "Attention" "REBOOT REQUIRED"
    echo -ne "${C_PROMPT}Do you want to reboot now? [Y/n]${C_RESET} "
    read -r resp
    if [ "$resp" != "n" ] && [ "$resp" != "N" ]; then sudo reboot; fi
else
    draw_header "Update Finished" "System secure and up to date"
    echo -ne "${C_PROMPT}Press any key to exit...${C_RESET} "
    read -n 1 -s -r
fi

kill $(ps -ho ppid -p $(ps -ho ppid -p $$))
exit 0
