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
    local risk_score=0
    local hit_buffer=""

    # Helper to add to buffer
    add_hit() { hit_buffer="${hit_buffer}\n ${1}"; ((risk_score += ${2})); }

    # --- 1. CORE SYSTEM VITALITY (Critical) ---
    if echo "$list" | grep -Ei "libc6|systemd|init|udev|kmod|dbus|pam|login" >/dev/null; then
        add_hit "${C_NALA_R}󰒔 OS Core:${C_RESET} Base libraries/Init system targeted. High breakage risk." 40
    fi

    # --- 2. BOOTLOADER & ENCRYPTION ---
    if echo "$list" | grep -Ei "grub|flash-kernel|dracut|initramfs|cryptsetup|luks|efibootmgr" >/dev/null; then
        add_hit "${C_WARN}󰐥 Boot & Encryption:${C_RESET} Bootloader or LUKS hooks. System may not boot." 30
    fi

    # --- 3. KERNEL & LOW-LEVEL HARDWARE ---
    if echo "$list" | grep -Ei "linux-image|linux-headers|firmware-linux|microcode" >/dev/null; then
        add_hit "${C_PROMPT}󰓅 Kernel/Firmware:${C_RESET} Active kernel or CPU microcode changes." 15
    fi

    # --- 4. GRAPHICAL DESKTOPS (DE) ---
    if echo "$list" | grep -Ei "gnome|plasma|kde|xfce|lxqt|mate|cinnamon|enlightenment" >/dev/null; then
        add_hit "${C_WARN}󰍹 Desktop Env:${C_RESET} Major Desktop components removal." 25
    fi

    # --- 5. WINDOW MANAGERS & COMPOSITORS ---
    if echo "$list" | grep -Ei "kwin|mutter|sway|wlroots|weston|openbox|i3|hyprland|fluxbox" >/dev/null; then
        add_hit "${C_WARN}󰨇 Window Manager:${C_RESET} Display orchestration components targeted." 20
    fi

    # --- 6. DISPLAY STACK & PROTOCOLS ---
    if echo "$list" | grep -Ei "xserver|xorg|wayland|libx11|libwayland|xwayland" >/dev/null; then
        add_hit "${C_PROMPT}󰢮 Display Stack:${C_RESET} X11 or Wayland protocols shifting." 15
    fi

    # --- 7. GPU DRIVERS & ACCELERATION ---
    if echo "$list" | grep -Ei "nvidia|mesa|vulkan|libdrm|intel-gpu|amdgpu|va-api|vdpau" >/dev/null; then
        add_hit "${C_PROMPT}󰢮 Graphics Pipeline:${C_RESET} Driver or acceleration library removal." 15
    fi

    # --- 8. AUDIO SERVER & CODECS ---
    if echo "$list" | grep -Ei "pipewire|pulseaudio|alsa|wireplumber|jackd|libavcodec|ffmpeg" >/dev/null; then
        add_hit "${C_PROMPT}󰓃 Audio/Media:${C_RESET} Sound server or essential codecs." 10
    fi

    # --- 9. NETWORK & CONNECTIVITY ---
    if echo "$list" | grep -Ei "network-manager|nmtui|wpasupplicant|iwd|bluez|bluetooth|modemmanager" >/dev/null; then
        add_hit "${C_WARN}󰖩 Connectivity:${C_RESET} Loss of Wi-Fi, Ethernet, or Bluetooth likely." 20
    fi

    # --- 10. VPN & securuty PROTOCOLS ---
    if echo "$list" | grep -Ei "openvpn|wireguard|strongswan|libssl|openssl|ca-certificates" >/dev/null; then
        add_hit "${C_WARN}󰖂 VPN/Security:${C_RESET} SSL libraries or VPN tunnel engines." 15
    fi

    # --- 11. VIRTUALIZATION & CONTAINERS ---
    if echo "$list" | grep -Ei "docker|containerd|qemu|libvirt|virtualbox|podman" >/dev/null; then
        add_hit "${C_PROMPT}󰡄 Virtualization:${C_RESET} VM or Container workloads may fail." 10
    fi

    # --- 12. DEVELOPER TOOLCHAIN ---
    if echo "$list" | grep -Ei "gcc-|clang-|binutils|make|dkms|cmake|python3" >/dev/null; then
        add_hit "${C_PROMPT}󰅩 Toolchain:${C_RESET} Compilers or headers. Impacts driver builds." 10
    fi

    # --- 13. INPUT METHODS (Multilingual) ---
    if echo "$list" | grep -Ei "fcitx|uim|ibus|anthy|hime|maliit" >/dev/null; then
        add_hit "${C_WARN}󰟷 Input Methods:${C_RESET} Complex typing engines (CJK/Phonetic)." 15
    fi

    # --- 14. FILESYSTEM TOOLS ---
    if echo "$list" | grep -Ei "btrfs-progs|xfsprogs|e2fsprogs|ntfs-3g|zfsutils" >/dev/null; then
        add_hit "${C_WARN}󰋊 Filesystem:${C_RESET} Disk management tools. Dangerous for RAID/Btrfs." 25
    fi

    # --- 15. PRINTERS & PERIPHERALS ---
    if echo "$list" | grep -Ei "cups|sane|avahi|ghostscript" >/dev/null; then
        add_hit "${C_PROMPT}󰐪 Peripherals:${C_RESET} Printing or Scanning support removal." 5
    fi

    # --- 16. SID TRANSITION STATUS ---
    if [[ "$KEPT_BACK_COUNT" -gt 10 ]]; then
        add_hit "${C_WARN}󰔶 Fragmentation:${C_RESET} $KEPT_BACK_COUNT packages are held back (Stall)." 20
    fi

    # --- 17. THE "SID TRAP" SYNERGY (Multipliers) ---
    # Detects if we are removing input/DE components while the repo is stalled
    if [[ "$KEPT_BACK_COUNT" -gt 100 ]] && echo "$list" | grep -Ei "fcitx|uim|plasma|kwin|gnome" >/dev/null; then
        add_hit "${C_NALA_R}󰔶 CRITICAL SYNERGY:${C_RESET} Removal during massive stall. Reinstall will fail." 40
    fi

    # Detect Major Version Transitions (Qt/Frameworks)
    local V_CHANGE=$(echo "$SIM_OUT" | grep -Ei "remv|inst" | grep -oEi "lib(kf[5-9]|qt[5-9]|gnome[0-9]|gtk[3-5]|glib[0-9])" | sort -u | wc -l)
    if [ "$V_CHANGE" -gt 1 ]; then
        add_hit "${C_PROMPT}󰔶 Transition:${C_RESET} Major library version jump detected (e.g. Qt5->6)." 15
    fi

    # --- OUTPUT INTERFACE ---
    draw_separator "DETAILED RISK ASSESSMENT"

    # System Status Summary
    echo -e "${C_BOLD}System Audit Summary:${C_RESET}"
    echo -e " 󱔗 Packages Kept Back: ${C_WARN}${KEPT_BACK_COUNT}${C_RESET}"
    echo -e " 󰆴 Packages to Remove: ${C_NALA_R}${REMOVAL_COUNT}${C_RESET}"

    echo -e "\n${C_BOLD}Detection Categories Found:${C_RESET}"
    echo -e "$hit_buffer"

    echo -ne "\n${C_BOLD}TOTAL RISK SCORE:${C_RESET} "
    if [ $risk_score -ge 75 ]; then
        echo -e "${C_NALA_R}${risk_score} - CRITICAL (Manual Abort Recommended)${C_RESET}"
    elif [ $risk_score -ge 45 ]; then
        echo -e "${C_WARN}${risk_score} - HIGH (Backup Required)${C_RESET}"
    else
        echo -e "${C_PROMPT}${risk_score} - MODERATE (Standard Sid Flow)${C_RESET}"
    fi
}

# --- Helper: The Spinner Engine ---
# This is a safe version that won't orphan processes
start_spinner() {
    local msg="$1"
    echo -ne "${C_BORDER}󰏓 ${msg}... ${C_RESET}"
    # Start the spinner in a subshell
    (
        local delay=0.1
        local spinstr='|/-\'
        while [ true ]; do
            local temp=${spinstr#?}
            printf " [%c]  " "$spinstr"
            local spinstr=$temp${spinstr%"$temp"}
            sleep $delay
            printf "\b\b\b\b\b\b"
        done
    ) &
    SPIN_PID=$!
}

stop_spinner() {
    kill $SPIN_PID >/dev/null 2>&1
    wait $SPIN_PID 2>/dev/null
    echo -ne "\b\b\b\b\b\b" # Clean up the spinner characters
}

# --- 2. Initial Check ---
clear
draw_progress
draw_header "Initial Check" "Analyzing all package managers..."
echo -e "${C_PROMPT}Requesting administrator privileges...${C_RESET}"
sudo ls >/dev/null
echo -e "Thanks\n"

# 2.1 APT/NALA TRUTH PROBE
start_spinner "APT/Nala: Updating Repositories"
sudo nala update >/dev/null 2>&1
stop_spinner
echo -e "${C_NALA_G}Done${C_RESET}"

start_spinner "APT/Nala: Probing Sid Transitions"
SIM_OUT=$(apt-get dist-upgrade -s 2>/dev/null)
APT_COUNT=$(echo "$SIM_OUT" | grep -c "^Inst")
stop_spinner

APT_UP=true
if [ "$APT_COUNT" -gt 0 ]; then
    APT_UP=false
    echo -e "${C_WARN}Updates Found ($APT_COUNT)${C_RESET}"
else
    echo -e "${C_NALA_G}Up to date${C_RESET}"
fi

# 2.2 FLATPAK
if command -v flatpak &>/dev/null; then
    start_spinner "Flatpak:  Checking Runtimes"
    FP_UP=true
    if echo "n" | sudo flatpak update 2>&1 | grep -iqE "ID|Updating|Installing"; then
        FP_UP=false
        stop_spinner
        echo -e "${C_WARN}Updates Found${C_RESET}"
    else
        stop_spinner
        echo -e "${C_NALA_G}Up to date${C_RESET}"
    fi
fi

# 2.3 SNAP
if command -v snap &>/dev/null; then
    start_spinner "Snap:     Checking Refresh List"
    SNAP_UP=true
    # We store the result to check it after the spinner stops
    SNAP_CHECK=$(sudo snap refresh --list 2>&1 | grep -v 'All snaps up to date')
    stop_spinner
    if [ -n "$SNAP_CHECK" ]; then
        SNAP_UP=false
        echo -e "${C_WARN}Updates Found${C_RESET}"
    else
        echo -e "${C_NALA_G}Up to date${C_RESET}"
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

        headshow=8

        # Show only first $headshow packages to keep the UI clean
        echo "$REMOVAL_LIST" | head -n $headshow | sed 's/^/  - /'

        # If there are more than $headshow, show the remaining count
        if [ "$REMOVAL_COUNT" -gt $headshow ]; then
            echo -e "  ${C_BORDER}... and $((REMOVAL_COUNT - $headshow)) more packages.${C_RESET}"
        fi

        echo -e "\n${C_BOLD}Trigger:${C_RESET} $([ -n "$CRITICAL_HIT" ] && echo "Critical system component hit!" || echo "Mass removal ($REMOVAL_COUNT packages) exceeds limit ($MAX_DELETIONS).")"

        echo -ne "\n${C_PROMPT}Proceed anyway? (Check 'Analysis of Risk' above!) [y/N]: ${C_RESET}"
        read -r danger_resp
        if [[ ! "$danger_resp" =~ ^[Yy]$ ]]; then
            # 1. Update State
            APT_UP=true
            APT_SKIPPED=true
            ((STEP+=2)) # Skip the APT execution steps in the progress bar

            # 2. Visual Pivot
            clear
            draw_progress
            draw_header "APT Upgrade Aborted" "Bypassing high-risk changes safely."

            echo -e "\n ${C_WARN}󰜺${C_RESET} ${C_BOLD}Status:${C_RESET} APT/Nala operations cancelled by user."
            echo -e " ${C_PROMPT}󰁯${C_RESET} ${C_BOLD}Next:${C_RESET} Moving to Flatpak and Snap managers..."

            # 3. Pause for the user to see the confirmation
            wait_user
            clear
        fi
    fi

# 3.0 Proceed
# Logic: Only show 'Already up to date' if we didn't just manually abort a danger

if [ "$APT_UP" = "true" ] && [ "$FP_UP" = "true" ] && [ "$SNAP_UP" = "true" ] && [ "$APT_SKIPPED" != "true" ]; then
    ((STEP+=6))
    draw_header "Status" "System is already fully up to date."
    wait_user
else
    # NEW LOGIC: If we are here but EVERYTHING is now 'true', it means we skipped APT
    # and Flatpak/Snap have nothing to do.
    if [ "$APT_UP" = "true" ] && [ "$FP_UP" = "true" ] && [ "$SNAP_UP" = "true" ]; then
        draw_header "Status" "APT Upgrade Skipped. No other updates pending."
        ((STEP+=4)) # Jump forward so we don't 'wait_user' twice
        wait_user
    else
        # 3.1 Standard Upgrade - Show only what is actually pending
        draw_header "Update Pending" "Available Upgrades"

        [ "$APT_UP" = "false" ] && echo -e " ${C_WARN}󰏓${C_RESET} APT Packages"
        [ "$FP_UP" = "false" ] && echo -e " ${C_WARN}󰏓${C_RESET} Flatpak Runtimes"
        [ "$SNAP_UP" = "false" ] && echo -e " ${C_WARN}󰏓${C_RESET} Snap Daemons"

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
fi

# --- 4. Cleanup Branch ( High-Precision Mode) ---
clear
draw_progress
draw_header "Maintenance" "Final System Optimization"
echo -ne "\n${C_PROMPT}Run deep system cleanup? [y/N]${C_RESET} "
read -r resp
if [[ ! "$resp" =~ ^[Yy]$ ]]; then
    STEP=14
    echo -e "${C_WARN}Cleanup skipped by user.${C_RESET}"
    wait_user
else
    ((STEP++))

    # 4.1 Precision Kernel Modules Cleanup
    clear
    draw_progress
    draw_header "Cleanup 1/5" "Analyzing Orphaned Kernel Modules"

    pre_k=$(du -sb /lib/modules 2>/dev/null | cut -f1)
    pre_k=${pre_k:-0}
    RUNNING_K=$(uname -r)

    echo -e "${C_BORDER}Kernel Verification Phase:${C_RESET}"
    echo -e "  Active Kernel: ${C_PROMPT}$RUNNING_K${C_RESET}"
    INSTALLED_KS=$(dpkg -l 'linux-image-*' 2>/dev/null | grep '^ii' | awk '{print $2}' | sed 's/linux-image-//g')

    draw_separator "Scanning /lib/modules Path"
    for mod_dir in /lib/modules/*; do
        [ -d "$mod_dir" ] || continue
        k_ver=$(basename "$mod_dir")

        # Check system load before I/O intensive removal
        LOAD_K=$(awk '{print $1}' /proc/loadavg)

        if [ "$k_ver" == "$RUNNING_K" ]; then
            echo -e "  [${C_PROMPT}SAFE${C_RESET}] Running: $k_ver"
            continue
        fi

        MATCH_FOUND=false
        for inst_k in $INSTALLED_KS; do
            if [[ "$k_ver" == "$inst_k"* ]]; then MATCH_FOUND=true; break; fi
        done

        if [ "$MATCH_FOUND" = true ]; then
            echo -e "  [${C_BORDER}KEEP${C_RESET}] Registered: $k_ver"
        else
            echo -e "  [${C_WARN}PURGE${C_RESET}] Orphaned: $k_ver (System Load: $LOAD_K)"
            sudo rm -rf "$mod_dir"
            # Verification: Did it actually delete?
            [ ! -d "$mod_dir" ] && echo -e "      -> ${C_NALA_G}Verified Success${C_RESET}" || echo -e "      -> ${C_NALA_R}Removal Failed${C_RESET}"
        fi
    done

    post_k=$(du -sb /lib/modules 2>/dev/null | cut -f1)
    post_k=${post_k:-0}
    diff_k=$(( pre_k - post_k ))
    [ "$diff_k" -gt 0 ] && TOTAL_FREED=$(( TOTAL_FREED + diff_k ))
    wait_user

    # 4.2 Cache Maintenance (Nala & APT)
    clear
    draw_progress
    draw_header "Cleanup 2/5" "Package Cache Purge"
    pre_c=$(du -sb /var/cache/apt/archives 2>/dev/null | cut -f1 || echo 0)

    echo -e "${C_BORDER}Clearing Nala & APT caches...${C_RESET}"
    sudo nala clean
    sudo apt-get autoclean -y
    sudo apt-get autoremove --purge -y

    post_c=$(du -sb /var/cache/apt/archives 2>/dev/null | cut -f1 || echo 0)
    TOTAL_FREED=$(( TOTAL_FREED + pre_c - post_c ))
    wait_user

    # 4.3 Residual Configs (Deep Scan)
    clear
    draw_progress
    draw_header "Cleanup 3/5" "Residual Configuration Files"
    purgestr=$(COLUMNS=200 dpkg -l | grep "^rc" | awk '{print $2}')
    if [ -n "$purgestr" ]; then
        echo -e "${C_WARN}Found leftover configs for:${C_RESET}"
        echo "$purgestr" | sed 's/^/  - /'
        sudo dpkg --purge $purgestr
    else
        echo -e "${C_PROMPT}Success:${C_RESET} No residual configs detected."
    fi
    wait_user

    # 4.4 Multi-Point Journal Vacuuming
    clear
    draw_progress
    draw_header "Cleanup 4/5" "Log Rotation & Journal Vacuuming"
    pre_l=$(du -sb /var/log/journal 2>/dev/null | cut -f1 || echo 0)

    echo -e "${C_BORDER}Vacuuming Systemd Journal (Retention: 7 days / 100M)...${C_RESET}"
    sudo journalctl --vacuum-time=7d
    sudo journalctl --vacuum-size=100M

    post_l=$(du -sb /var/log/journal 2>/dev/null | cut -f1 || echo 0)
    TOTAL_FREED=$(( TOTAL_FREED + pre_l - post_l ))
    draw_separator "Journal Cleaned"
    wait_user

    # 4.5 DKMS Depth Check (Precision Verification)
    clear
    draw_progress
    draw_header "Cleanup 5/5" "DKMS Build Integrity Verification"
    if type -p dkms &>/dev/null; then
        DKMS_LIST=$(sudo dkms status)
        if echo "$DKMS_LIST" | grep -qi "Error"; then
            echo -e "${C_NALA_R}CRITICAL:${C_RESET} DKMS Build Failure detected!"
            echo "$DKMS_LIST" | grep -i "Error"
        else
            echo -e "${C_PROMPT}Integrity Check:${C_RESET} All kernel modules verified."
            echo "$DKMS_LIST" | sed 's/^/  /'
        fi
    else
        echo -e "${C_WARN}Note:${C_RESET} DKMS not found. Skipping driver check."
    fi
    sync # Final  Buffer Flush
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
