#!/bin/bash

##################################################################
#                Pretty System Update - Precision                #
#             Developed by sergio melas  2021-26                 #
#             Version: Sid Specialized (Triple-Check Logic)      #
##################################################################

# --- 0. Environment Fix (Ensures sbin tools like dkms are found) ---
export PATH="/usr/local/sbin:/usr/sbin:/sbin:$PATH"

# --- Colors ---
C_BORDER='\e[96m'; C_TEXT='\e[97m'; C_BOLD='\e[1m'; C_WARN='\e[93m'
C_PROMPT='\e[92m'; C_NALA_G='\e[32m'; C_NALA_R='\e[31m'; C_RESET='\e[0m'

# --- 1. Progress Engine and helpers---
STEP=1
TOTAL_STEPS=15
TOTAL_FREED=0

draw_progress() {
    local width=79
    local percent=$(( (STEP * 100) / TOTAL_STEPS ))
    local filled=$(( (STEP * width) / TOTAL_STEPS ))
    local empty=$(( width - filled ))
    echo -ne "${C_NALA_G}"
    for i in $(seq 1 $filled); do echo -n "━"; done
    echo -ne "${C_NALA_R}"
    for i in $(seq 1 $empty); do echo -n "━"; done
    echo -e "${C_RESET}\n Progress: ${percent}%"
}

draw_header() {
    local title="$1"
    local tip="$2"
    local width=79
    local title_len=${#title}
    local bar_len=$((width - title_len - 5))
    if [ "$bar_len" -lt 1 ]; then bar_len=1; fi

    echo -ne "${C_BORDER}┏━${C_TEXT}${C_BOLD} ${title} ${C_RESET}${C_BORDER}$(printf '━%.0s' $(seq 1 $bar_len))┓\n"
    echo -ne "┃${C_RESET}  ${tip}$(printf ' %.0s' $(seq 1 $((width - ${#tip} - 4))))${C_BORDER}┃\n"
    echo -e "┗$(printf '━%.0s' $(seq 1 $((width - 2))))┛${C_RESET}"
}

draw_separator() {
    local text="$1"
    local width=79
    local text_len=${#text}
    local side_bar=$(( (width - text_len - 2) / 2 ))
    if [ "$side_bar" -lt 1 ]; then side_bar=1; fi
    echo -ne "\n${C_BORDER}$(printf '━%.0s' $(seq 1 $side_bar))${C_TEXT}${C_BOLD} ${text} ${C_RESET}${C_BORDER}$(printf '━%.0s' $(seq 1 $side_bar))${C_RESET}\n"
}

wait_user() {
    echo -ne "\n${C_WARN}Press any key to continue...${C_RESET} "
    read -n 1 -s -r
    echo ""
    ((STEP++))
}

explain_danger() {
    local list="$1"
    # Changed header to Yellow (C_WARN)
    echo -e "${C_WARN}${C_BOLD}Analysis of Risk:${C_RESET}"

    # Check for Input Methods - Yellow
    if echo "$list" | grep -Ei "fcitx|uim|ibus|anthy" >/dev/null; then
        echo -e " ${C_WARN}󰟷${C_RESET} Removal of ${C_BOLD}Input Methods${C_RESET} (Non-Latin typing may break)."
    fi

    # Check for Desktop Environment - Changed from Red to Yellow
    if echo "$list" | grep -Ei "gnome|plasma|kde|xfce|sway|kwin|mutter" >/dev/null; then
        echo -e " ${C_WARN}󰍹${C_RESET} Removal of ${C_BOLD}Desktop Components${C_RESET} (GUI may fail to start)."
    fi

    # Check for Graphics/Drivers - Yellow
    if echo "$list" | grep -Ei "nvidia|mesa|xserver|wayland|drm" >/dev/null; then
        echo -e " ${C_WARN}󰢮${C_RESET} Removal of ${C_BOLD}Display Drivers${C_RESET} (Screen/3D issues)."
    fi

    # Check for System Core - Changed from Red to Yellow
    if echo "$list" | grep -Ei "libc6|systemd|init|udev" >/dev/null; then
        echo -e " ${C_WARN}󰒔${C_RESET} Removal of ${C_BOLD}System Core${C_RESET} (OS likely to break)."
    fi

    # Check for Fragmentation (The "Kept Back" problem) - MULTILINE FIX
    if [[ "$KEPT_BACK_COUNT" -gt 50 ]]; then
        echo -e " ${C_WARN}󰔶${C_RESET} Notice: ${C_BOLD}$KEPT_BACK_COUNT packages${C_RESET} are being 'kept back'."
        echo -e "   ${C_WARN}Alert:${C_RESET} Repository Mismatch Detected. Proceeding now will leave"
        echo -e "   your system in an unstable, partial upgrade state because"
        echo -e "   many dependencies are currently 'held back'."
    fi

    # Major Version Transitions (Dynamic check)
    if [[ "$REMOVAL_COUNT" -gt 15 ]]; then
        local V_CHANGE=$(echo "$SIM_OUT" | grep -Ei "remv|inst" | grep -oEi "lib(kf[5-9]|qt[5-9]|gnome[0-9])" | sort -u | wc -l)
        if [ "$V_CHANGE" -gt 1 ]; then
            echo -e " ${C_PROMPT}󰔶${C_RESET} Notice: This appears to be a ${C_BOLD}Major Version Transition${C_RESET}."
            echo -e "   (Old libraries are being swapped for newer versions)."
        fi
    fi
    # Check for Replacements (Swapping fcitx5 for fcitx, etc.)
    if echo "$SIM_OUT" | grep -q "NEW packages will be installed"; then
        echo -e " ${C_PROMPT}󰁯${C_RESET} Note: Some removed packages have ${C_BOLD}replacements${C_RESET} pending."
    fi
}

# --- 2. Initial Check ---
clear
draw_progress
draw_header "Initial Check" "Analyzing all package managers..."
echo -e "${C_PROMPT}Requesting administrator privileges...${C_RESET}"
sudo ls >/dev/null
echo "Thanks"

# 2.1 APT TRUTH PROBE (Simulating Full-Upgrade for Sid Transitions)
sudo nala update >/dev/null 2>&1
# We capture the full simulation of a dist-upgrade to see the REAL plan
SIM_OUT=$(apt-get dist-upgrade -s 2>/dev/null)

# Logic: Count "Inst" lines to see if there are updates available
APT_COUNT=$(echo "$SIM_OUT" | grep -c "^Inst")

APT_UP=true
if [ "$APT_COUNT" -gt 0 ]; then
    APT_UP=false
fi

# 2.2 FLATPAK (The "Safe & Certain" Probe)
FP_UP=true
if command -v flatpak &>/dev/null; then
    # We pipe 'n' into the update command to see the table without installing
    if echo "n" | sudo flatpak update 2>&1 | grep -iqE "ID|Updating|Installing"; then
        FP_UP=false
    fi
fi

# 2.3 SNAP (Strict refresh check)
SNAP_UP=true
if command -v snap &>/dev/null; then
    # Filter out the "All snaps up to date" text and count real lines
    if [ -n "$(sudo snap refresh --list 2>&1 | grep -v 'All snaps up to date')" ]; then
        SNAP_UP=false
    fi
fi

# 2.4 SID SENTINEL (Domino Effect & Mass Removal Detection)
MAX_DELETIONS=5
# Improved removal count: captures both forced 'Remv' and 'will be REMOVED' blocks
REMOVAL_LIST=$(echo "$SIM_OUT" | grep -Ei "^Remv |will be REMOVED" | grep -v "installed" | awk '{print $2}')
REMOVAL_COUNT=$( [ -z "$REMOVAL_LIST" ] && echo 0 || echo "$REMOVAL_LIST" | wc -l )

# Critical hits (Core Desktop components)
CRITICAL_HIT=$(echo "$REMOVAL_LIST" | grep -Ei "gnome|plasma|kde|xfce|sway|libc6|systemd|xorg|wayland")

# Fragmentation Check: Extract the number from the "...and 207 not upgraded" string
KEPT_BACK_COUNT=$(echo "$SIM_OUT" | grep "not upgraded" | grep -oEi "[0-9]+ not upgraded" | awk '{print $1}')
[ -z "$KEPT_BACK_COUNT" ] && KEPT_BACK_COUNT=0

APT_DANGER=false
# Trigger danger if:
# 1. Mass removal (>5)
# 2. Critical component hit
# 3. High fragmentation (>50 packages kept back - indicates a broken repo state)
if [ "$REMOVAL_COUNT" -gt "$MAX_DELETIONS" ] || [ -n "$CRITICAL_HIT" ] || [ "$KEPT_BACK_COUNT" -gt 50 ]; then
    APT_DANGER=true
fi

# --- 3. Update Branch ---
# 3.0 EMERGENCY BRAKE
    if [ "$APT_DANGER" = "true" ]; then
        clear
        draw_progress
        draw_header "!!! DANGER DETECTED !!!" "Potential System Destruction Found"

        # Call the risk translator
        explain_danger "$REMOVAL_LIST"

        echo -ne "\n${C_NALA_R}${C_BOLD}Technical Removal List (Summary):${C_RESET}\n"

        # Show only first 10 packages to keep the UI clean
        echo "$REMOVAL_LIST" | head -n 10 | sed 's/^/  - /'

        # If there are more than 10, show the remaining count
        if [ "$REMOVAL_COUNT" -gt 10 ]; then
            echo -e "  ${C_BORDER}... and $((REMOVAL_COUNT - 10)) more packages.${C_RESET}"
        fi

        echo -e "\n${C_BOLD}Trigger:${C_RESET} $([ -n "$CRITICAL_HIT" ] && echo "Critical system component hit!" || echo "Mass removal ($REMOVAL_COUNT packages) exceeds limit ($MAX_DELETIONS).")"

        echo -ne "\n${C_PROMPT}Proceed anyway? (Check 'Analysis of Risk' above!) [y/N]: ${C_RESET}"
        read -r danger_resp
        if [[ ! "$danger_resp" =~ ^[Yy]$ ]]; then
            echo -e "${C_WARN}APT Upgrade aborted. Skipping to other managers...${C_RESET}"
            APT_UP=true
            wait_user
            clear
        fi
    fi

# 3.0 Proceed

if [ "$APT_UP" = "true" ] && [ "$FP_UP" = "true" ] && [ "$SNAP_UP" = "true" ]; then
    ((STEP+=6))
    draw_header "Status" "System is already fully up to date."
    wait_user
else
    # 3.1 Standard Upgrade
    draw_header "Update Pending" "Avalible Upgrades"

    if [ "$APT_UP" = "false" ]; then
        echo -ne "\n${C_WARN}- APT Upgrades${C_RESET} "
    fi

    if [ "$FP_UP" = "false" ]; then
        echo -ne "\n${C_WARN}- FLATPAK Upgrades${C_RESET} "
    fi

    if [ "$SNAP_UP" = "false" ]; then
        echo -ne "\n${C_WARN}- SNAP Upgrades${C_RESET} "
    fi

    wait_user
    clear
    draw_progress
    draw_header "Update Pending" "Performing standard package upgrade"


    if [ "$APT_UP" = "false" ]; then
        sudo nala upgrade --autoremove --install-recommends --fix-broken --purge --no-update
    fi
    ((STEP++))

    # 3.2 Sid Full-Upgrade
    clear
    draw_progress
    draw_header "Sid Full-Upgrade" "Intelligent package transitions (Dist-Upgrade)"
    if [ "$APT_UP" = "false" ]; then
        echo -ne "\n${C_PROMPT}Run nala full-upgrade? [y/N]${C_RESET} "
        read -r full_resp
        if [ "$full_resp" = "y" ] || [ "$full_resp" = "Y" ]; then
            sudo nala full-upgrade --autoremove --purge --no-update
        fi
    fi
    ((STEP++))

    # 3.3 Flatpak Update
    clear
    draw_progress
    draw_header "Flatpak" "Updating Flatpak runtimes and apps"
    if [ "$FP_UP" = "false" ]; then
        sudo flatpak update -y
    fi
    ((STEP++))

    # 3.4 Snap Update
    clear
    draw_progress
    draw_header "Snap" "Refreshing Snap packages"
    if [ "$SNAP_UP" = "false" ]; then
        sudo snap refresh
    fi
    ((STEP++))

    wait_user
fi

# --- 4. Cleanup Branch ---
clear
draw_progress
draw_header "Maintenance" "Check for cleanup?"
echo -ne "\n${C_PROMPT}Run system cleanup? [y/N]${C_RESET} "
read -r resp
if [ "$resp" != "y" ] && [ "$resp" != "Y" ]; then
    STEP=14
    wait_user
else
    ((STEP++))

    # 4.1 Precision Kernel Modules Cleanup (ORIGINAL VERBOSE)
    clear
    draw_progress
    draw_header "Cleanup 1/5" "Removing orphaned kernel modules"
    pre_k=$(du -sb /lib/modules 2>/dev/null | cut -f1)
    pre_k=${pre_k:-0}
    RUNNING_K=$(uname -r)
    INSTALLED_KS=$(dpkg -l 'linux-image-*' 2>/dev/null | grep '^ii' | awk '{print $2}' | sed 's/linux-image-//g')

    draw_separator "Scanning /lib/modules"
    for mod_dir in /lib/modules/*; do
        [ -d "$mod_dir" ] || continue
        k_ver=$(basename "$mod_dir")
        if [ "$k_ver" == "$RUNNING_K" ]; then
            echo -e " ${C_PROMPT}Keep (Running):${C_RESET} $k_ver"
            continue
        fi
        MATCH_FOUND=false
        for inst_k in $INSTALLED_KS; do
            if [ "$k_ver" == "$inst_k" ]; then
                MATCH_FOUND=true
                break
            fi
        done
        if [ "$MATCH_FOUND" = true ]; then
            echo -e " ${C_BORDER}Keep (Installed):${C_RESET} $k_ver"
        else
            echo -e " ${C_WARN}Removing Orphaned Modules:${C_RESET} $k_ver"
            sudo rm -rf "$mod_dir"
        fi
    done

    post_k=$(du -sb /lib/modules 2>/dev/null | cut -f1)
    post_k=${post_k:-0}
    diff_k=$(( pre_k - post_k ))
    if [ "$diff_k" -gt 0 ]; then
        TOTAL_FREED=$(( TOTAL_FREED + diff_k ))
        draw_separator "Kernel Space Recovered"
        echo -e "    ${C_BOLD}$(numfmt --to=iec-i --suffix=B $diff_k)${C_RESET}"
    fi
    wait_user

    # 4.2 Package Cache
    clear
    draw_progress
    draw_header "Cleanup 2/5" "Package Cache"
    pre_c1=$(du -sb /var/cache/apt/archives 2>/dev/null | cut -f1)
    pre_c2=$(du -sb /var/cache/nala 2>/dev/null | cut -f1)
    pre_c=$(( ${pre_c1:-0} + ${pre_c2:-0} ))
    sudo apt autoclean; sudo apt --purge autoremove; sudo nala clean
    post_c1=$(du -sb /var/cache/apt/archives 2>/dev/null | cut -f1)
    post_c2=$(du -sb /var/cache/nala 2>/dev/null | cut -f1)
    post_c=$(( ${post_c1:-0} + ${post_c2:-0} ))
    diff_c=$(( pre_c - post_c ))
    if [ "$diff_c" -gt 0 ]; then
        TOTAL_FREED=$(( TOTAL_FREED + diff_c ))
        draw_separator "Cache Space Recovered"
        echo -e "   ${C_BOLD}$(numfmt --to=iec-i --suffix=B $diff_c)${C_RESET}"
    fi
    wait_user

    # 4.3 Old Configurations
    clear
    draw_progress
    draw_header "Cleanup 3/5" "Old Configurations"
    purgestr=$(COLUMNS=200 dpkg -l | grep "^rc" | awk '{print $2}')
    if [ -n "$purgestr" ]; then
        sudo dpkg --purge $purgestr
    else
        echo "No residual configs found."
    fi
    wait_user

    # 4.4 System Logs
    clear
    draw_progress
    draw_header "Cleanup 4/5" "System Logs"
    pre_l=$(du -sb /var/log/journal 2>/dev/null | cut -f1 || echo 0)
    sudo journalctl --vacuum-size=100M
    post_l=$(du -sb /var/log/journal 2>/dev/null | cut -f1 || echo 0)
    diff_l=$(( pre_l - post_l ))
    if [ "$diff_l" -gt 0 ]; then
        TOTAL_FREED=$(( TOTAL_FREED + diff_l ))
    fi
    draw_separator "Total Vacuumed Space from logs"
    echo -e "    ${C_BOLD}$(numfmt --to=iec-i --suffix=B ${diff_l:-0})${C_RESET}"
    wait_user

    # 4.5 DKMS Driver Verification
    clear
    draw_progress
    draw_header "Cleanup 5/5" "Verifying DKMS Driver Integrity"
    if type -p dkms &>/dev/null; then
        sudo dkms status
    else
        echo -e "${C_WARN}DKMS binary not found in PATH (/usr/sbin).${C_RESET}"
    fi
    wait_user
fi

# --- 5. Final Results & Interactive Reboot ---
clear
draw_progress
FREED_HUMAN=$(numfmt --to=iec-i --suffix=B $(( TOTAL_FREED > 0 ? TOTAL_FREED : 0 )))
draw_header "Complete" "SESSION SAVINGS: $FREED_HUMAN"

if [ -f /var/run/reboot-required ]; then
    echo -e "${C_WARN}${C_BOLD}ATTENTION: A REBOOT IS REQUIRED TO FINISH UPDATES.${C_RESET}"
    echo -ne "\n${C_PROMPT}Would you like to reboot now? [y/N] ${C_RESET}"
    read -r reboot_resp
    if [[ "$reboot_resp" =~ ^[Yy]$ ]]; then
        echo -e "${C_BOLD}Rebooting...${C_RESET}"
        sudo reboot
    else
        echo -e "${C_WARN}Reboot postponed. Remember to restart soon.${C_RESET}"
        wait_user
    fi
else
    echo -e "${C_PROMPT}System optimized. No reboot needed.${C_RESET}"
    wait_user
fi

# --- 6. Exit ---
clear
STEP=$TOTAL_STEPS
draw_progress
draw_header "Goodbye" "Process complete."
sleep 1
kill $(ps -ho ppid -p $(ps -ho ppid -p $$)) 2>/dev/null
exit 0
