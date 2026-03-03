#!/bin/bash

##################################################################
#               Pretty System Update - Precision                 #
#            Developed by sergio melas  2021-26                  #
##################################################################

# --- Colors ---
C_BORDER='\e[96m'; C_TEXT='\e[97m'; C_BOLD='\e[1m'; C_WARN='\e[93m'
C_PROMPT='\e[92m'; C_NALA_G='\e[32m'; C_NALA_R='\e[31m'; C_RESET='\e[0m'

# --- 1. Progress Engine ---
STEP=1
TOTAL_STEPS=12
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

# Silent Variable Capture
UP_MSG=$(sudo nala update 2>&1)

APT_UP=true
if echo "$UP_MSG" | grep -qE "[1-9][0-9]* packages can be upgraded"; then
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
    # No clear, no new bar. Just print the status box below.
    ((STEP++))
    draw_header "Status" "System is already fully up to date."
    wait_user # Single pause to see the result
else
    # If updates ARE found, we clear to give Nala/Flatpak room to work
    ((STEP++))
    clear
    draw_progress
    draw_header "Update Pending" "New packages found"

    if [ "$APT_UP" = "false" ]; then
        sudo nala upgrade --autoremove --install-recommends --fix-broken --purge --no-update
    fi
    ((STEP++))
    if [ "$FP_UP" = "false" ]; then
        sudo flatpak update -y
    fi
    ((STEP++))
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
    STEP=10
    wait_user
else
    ((STEP++))

    # 4.1 Kernel Modules
    clear
    draw_progress
    draw_header "Cleanup 1/4" "Removing unused kernel modules"
    pre_k=$(du -sb /lib/modules 2>/dev/null | cut -f1)
    pre_k=${pre_k:-0}
    modulestr=$(dpkg -S /lib/modules/* 2>&1 | grep "no path found" | awk '{ print $NF }')
    if [ -n "$modulestr" ]; then
        for i in $modulestr; do
            if [[ "$i" != *'amd64'* ]]; then
                echo "Removing: $i"
                sudo rm -rf "$i"
            else
                echo "Skipping stock kernel: $i"
            fi
        done
    else
        echo "No modules to remove."
    fi
    post_k=$(du -sb /lib/modules 2>/dev/null | cut -f1)
    post_k=${post_k:-0}
    diff_k=$(( pre_k - post_k ))
    if [ "$diff_k" -gt 0 ]; then
        TOTAL_FREED=$(( TOTAL_FREED + diff_k ))
        draw_separator "Kernel Space Recovered"
        echo -e "   ${C_BOLD}$(numfmt --to=iec-i --suffix=B $diff_k)${C_RESET}"
    fi
    wait_user

    # 4.2 Package Cache
    clear
    draw_progress
    draw_header "Cleanup 2/4" "Package Cache"
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
    draw_header "Cleanup 3/4" "Old Configurations"
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
    draw_header "Cleanup 4/4" "System Logs"
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
