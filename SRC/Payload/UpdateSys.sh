#!/bin/bash

##################################################################
#                Pretty System Update - Precision                #
#             Developed by sergio melas  2021-26                 #
#             Version: Sid Specialized (Full-Upgrade)            #
##################################################################

# --- 0. Environment Fix (Path for DKMS/Sid) ---
export PATH="/usr/local/sbin:/usr/sbin:/sbin:$PATH"

# --- Colors ---
C_BORDER='\e[96m'; C_TEXT='\e[97m'; C_BOLD='\e[1m'; C_WARN='\e[93m'
C_PROMPT='\e[92m'; C_NALA_G='\e[32m'; C_NALA_R='\e[31m'; C_RESET='\e[0m'

# --- 1. Progress Engine ---
STEP=1
TOTAL_STEPS=15  # Incremented for DKMS Integrity Step
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
    ((STEP++))
}

# --- 2. Initial Check ---
clear
draw_progress
draw_header "Initial Check" "Analyzing repositories silently..."
echo -e "${C_PROMPT}Requesting administrator privileges...${C_RESET}"
sudo ls >/dev/null
echo "Thanks"

# SID FIX: Using Simulation to detect actionable updates
sudo nala update >/dev/null 2>&1
SIM_APT=$(sudo nala full-upgrade --no-update --simulate 2>&1)

APT_UP=true
if echo "$SIM_APT" | grep -qE "[1-9][0-9]* (upgraded|newly installed|removed)"; then
    APT_UP=false
fi

FP_UP=true
if command -v flatpak &>/dev/null; then
    if flatpak update --dry-run 2>&1 | grep -iqE "ID|Installing|Updating"; then
        FP_UP=false
    fi
fi

SNAP_UP=true
if command -v snap &>/dev/null; then
    if ! sudo snap refresh --list 2>&1 | grep -iqE "up to date|no updates"; then
        SNAP_UP=false
    fi
fi

# --- 3. Update Branch ---
if [ "$APT_UP" = "true" ] && [ "$FP_UP" = "true" ] && [ "$SNAP_UP" = "true" ]; then
    ((STEP+=6)) # Advance bar to maintenance section
    draw_header "Status" "System is already fully up to date."
    wait_user
else
    # 3.1 Normal Upgrade
    ((STEP++))
    clear
    draw_progress
    draw_header "Update Pending" "Performing standard package upgrade"
    if [ "$APT_UP" = "false" ]; then
        sudo nala upgrade --autoremove --install-recommends --fix-broken --purge --no-update
    else
        echo "All APT packages are up to date."
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
        else
            echo -e "${C_WARN}Skipping full-upgrade phase.${C_RESET}"
        fi
    else
        echo "No Full-Upgrade required."
    fi
    ((STEP++))

    # 3.3 Flatpak Update
    clear
    draw_progress
    draw_header "Flatpak" "Updating Flatpak runtimes and apps"
    if [ "$FP_UP" = "false" ]; then
        sudo flatpak update -y
    else
        echo "Flatpaks are up to date."
    fi
    ((STEP++))

    # 3.4 Snap Update
    clear
    draw_progress
    draw_header "Snap" "Refreshing Snap packages"
    if [ "$SNAP_UP" = "false" ]; then
        sudo snap refresh
    else
        echo "Snaps are up to date."
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
    STEP=13
    wait_user
else
    ((STEP++))

    # 4.1 Precision Kernel Modules Cleanup
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
    pre_conf=$(df / | tail -1 | awk '{print $3}')
    purgestr=$(COLUMNS=200 dpkg -l | grep "^rc" | awk '{print $2}')
    if [ -n "$purgestr" ]; then
        sudo dpkg --purge $purgestr
    else
        echo "No residual configs found."
    fi
    post_conf=$(df / | tail -1 | awk '{print $3}')
    diff_conf=$(( (pre_conf - post_conf) * 1024 ))
    if [ "$diff_conf" -gt 0 ]; then
        TOTAL_FREED=$(( TOTAL_FREED + diff_conf ))
        draw_separator "Config Space Recovered"
        echo -e "   ${C_BOLD}$(numfmt --to=iec-i --suffix=B $diff_conf)${C_RESET}"
    fi
    wait_user

    # 4.4 System Logs
    clear
    draw_progress
    draw_header "Cleanup 4/5" "System Logs"
    pre_l=$(du -sb /var/log/journal 2>/dev/null | cut -f1)
    sudo journalctl --vacuum-size=100M
    post_l=$(du -sb /var/log/journal 2>/dev/null | cut -f1)
    diff_l=$(( ${pre_l:-0} - ${post_l:-0} ))
    if [ "$diff_l" -gt 0 ]; then
        TOTAL_FREED=$(( TOTAL_FREED + diff_l ))
    fi
    draw_separator "Total Vacuumed Space from logs"
    echo -e "   ${C_BOLD}$(numfmt --to=iec-i --suffix=B ${diff_l:-0})${C_RESET}"
    wait_user

    # 4.5 DKMS Driver Verification (New Dedicated Reporting Step)
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

# --- 5. Final Results ---
clear
draw_progress
FREED_HUMAN=$(numfmt --to=iec-i --suffix=B $TOTAL_FREED)
if [ -f /var/run/reboot-required ]; then
    draw_header "Complete" "SESSION SAVINGS: $FREED_HUMAN"
    echo -e "${C_WARN}${C_BOLD}ATTENTION: REBOOT REQUIRED${C_RESET}"
    echo -ne "\n${C_PROMPT}Reboot now? [y/N]${C_RESET} "
    read -r resp
    if [ "$resp" = "y" ] || [ "$resp" = "Y" ]; then
        sudo reboot
    fi
else
    draw_header "Complete" "SESSION SAVINGS: $FREED_HUMAN"
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
