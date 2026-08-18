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

# --- Dynamic Relocating Star Engine ---
SHINE_PID=""
SAFE_STAR_SLOTS=()
START_Y=0
MAX_ACTIVE_STARS=5  # Change this integer to adjust maximum concurrent active stars

INIT_SAFE_SLOTS() {
    SAFE_STAR_SLOTS=(
        # Upper Screen Region (Above "SID SENTINEL ACTIVE")
        "10 24" "10 32" "10 40" "10 48" "10 56"
        "11 26" "11 36" "11 44" "11 54"
        "12 24" "12 34" "12 46" "12 56"

        # Rows 14, 15, 16 ARE STRICTLY EXCLUDED!
        # (Protects DEBIAN_ARCH, KERNEL, and RISK_LVL from being overwritten/erased)

        # Mid-Lower Screen Region (Below "by Sergio Melas")
        "18 26" "18 36" "18 46" "18 54"

        # Lowest Safe Interior Lines
        "20 24" "20 32" "20 40" "20 48" "20 56"
        "21 26" "21 34" "21 44" "21 54"
    )
}

shine_stars_daemon() {
    local glyphs=('.' '+' 'x' '*' '✦' '*' 'x' '+' '.')
    local colors=('\e[2;37m' '\e[0;97m' '\e[1;93m' '\e[1;96m' '\e[1;97m' '\e[1;96m' '\e[1;93m' '\e[0;97m' '\e[2;37m')

    # Convert relative slots to absolute screen lines
    local abs_slots=()
    for slot in "${SAFE_STAR_SLOTS[@]}"; do
        local parts=($slot)
        abs_slots+=("$((START_Y + parts[0])) ${parts[1]}")
    done

    # Active stars state derived from MAX_ACTIVE_STARS
    local num_stars=${MAX_ACTIVE_STARS:-4}
    local star_pos=()
    local star_step=()

    local pool_size=${#abs_slots[@]}
    for ((s=0; s<num_stars; s++)); do
        star_pos[s]=$(( (s * (pool_size / num_stars)) % pool_size ))
        star_step[s]=$(( s * 2 ))
    done

    # --- Walking Penguin Animation State ---
    # Rows 0-5: FIGlet logo | Rows 6-9: Clear middle corridor | Row 10+: IBM Box
    local PENGUIN_Y=$((START_Y + 2))  # Placed in the corridor between header and computer box
    local PENGUIN_X=4                 # Starting column offset
    local PENGUIN_MAX_X=70            # Reset column threshold
    local PENGUIN_COOLDOWN=0          # Pause between walking cycles
    local WALK_FRAME=0                # Frame toggle (0 or 1)

    # Trap exit signals to clean up star remnants and penguin sprite
    trap '
        for ((s=0; s<num_stars; s++)); do
            local coord=(${abs_slots[${star_pos[s]}]})
            tput sc
            tput cup ${coord[0]} ${coord[1]} 2>/dev/null
            echo -ne " "
            tput rc
        done
        for i in {0..2}; do
            tput sc
            tput cup $((PENGUIN_Y + i)) $((PENGUIN_X > 0 ? PENGUIN_X - 1 : 0)) 2>/dev/null
            echo -ne "      "
            tput rc
        done
        tput cnorm
        exit 0
    ' SIGTERM SIGINT

    tput civis

    while true; do
        # --- 1. Star Twinkle Step ---
        for ((s=0; s<num_stars; s++)); do
            local step=${star_step[s]}
            local pos_idx=${star_pos[s]}
            local coord=(${abs_slots[$pos_idx]})

            local r=${coord[0]}
            local c=${coord[1]}

            tput sc
            tput cup $r $c 2>/dev/null
            echo -ne "${colors[$step]}${glyphs[$step]}\e[0m"
            tput rc

            ((star_step[s]++))

            if [ ${star_step[s]} -ge ${#glyphs[@]} ]; then
                star_step[s]=0
                tput sc
                tput cup $r $c 2>/dev/null
                echo -ne " "
                tput rc
                star_pos[s]=$(( RANDOM % pool_size ))
            fi
        done

        # --- 2. Walking Penguin Animation ---
        if [ "$PENGUIN_COOLDOWN" -le 0 ]; then
            # Clean trailing space from the previous step
            local erase_x=$((PENGUIN_X - 1))
            [ "$erase_x" -lt 0 ] && erase_x=0

            tput sc
            for i in {0..2}; do
                tput cup $((PENGUIN_Y + i)) $erase_x 2>/dev/null
                echo -ne " "
            done
            tput rc

            # Render Animated Penguin Sprite
            if [ "$PENGUIN_X" -le "$PENGUIN_MAX_X" ]; then
                tput sc
                if [ "$WALK_FRAME" -eq 0 ]; then
                    # Frame 1: Left foot forward
                    tput cup $((PENGUIN_Y)) $PENGUIN_X 2>/dev/null
                    echo -ne "\e[1;97m (o_ \e[0m"
                    tput cup $((PENGUIN_Y + 1)) $PENGUIN_X 2>/dev/null
                    echo -ne "\e[1;97m//\\\\\ \e[0m"
                    tput cup $((PENGUIN_Y + 2)) $PENGUIN_X 2>/dev/null
                    echo -ne "\e[1;93m V_/_\e[0m"
                    WALK_FRAME=1
                else
                    # Frame 2: Right foot forward
                    tput cup $((PENGUIN_Y)) $PENGUIN_X 2>/dev/null
                    echo -ne "\e[1;97m (o_ \e[0m"
                    tput cup $((PENGUIN_Y + 1)) $PENGUIN_X 2>/dev/null
                    echo -ne "\e[1;97m//\\\\\ \e[0m"
                    tput cup $((PENGUIN_Y + 2)) $PENGUIN_X 2>/dev/null
                    echo -ne "\e[1;93m  _\_V\e[0m"
                    WALK_FRAME=0
                fi
                tput rc

                ((PENGUIN_X++)) # Move 1 column per tick
            else
                # Clean up final footprint at the end of the pass
                tput sc
                for i in {0..2}; do
                    tput cup $((PENGUIN_Y + i)) $((PENGUIN_MAX_X - 1)) 2>/dev/null
                    echo -ne "      "
                done
                tput rc

                PENGUIN_X=4
                PENGUIN_COOLDOWN=40 # Pause ~4 seconds before next walk
            fi
        else
            ((PENGUIN_COOLDOWN--))
        fi

        sleep 0.10
    done
}

start_shine() {
    [ ${#SAFE_STAR_SLOTS[@]} -eq 0 ] && return
    shine_stars_daemon &
    SHINE_PID=$!
}

stop_shine() {
    if [ -n "$SHINE_PID" ] && kill -0 "$SHINE_PID" 2>/dev/null; then
        kill -TERM "$SHINE_PID" 2>/dev/null
        wait "$SHINE_PID" 2>/dev/null
        SHINE_PID=""
    fi
}

show_logo() {
    # --- Local Color Definitions ---
    local G='\e[92m'       # Light Green
    local B='\e[1m'        # Bold
    local W='\e[97m'       # White
    local R='\e[0m'        # Reset
    local C_WARN='\e[93m'  # Yellow/Warning

    # --- Dynamic Telemetry ---
    local ARCH=$(uname -m)
    local KERNEL=$(uname -r | cut -d'-' -f1)

    # 1. FIGlet Style Header
    local R_RED='\e[91m'
    local R_ORG='\e[38;5;208m'
    local R_YEL='\e[93m'
    local R_GRN='\e[92m'
    local R_BLU='\e[94m'
    local tim=0.02

    CURRENT_LOGO_LINE=0

    echo -e "${R_RED}${B}               _   _ ____  ____    _  _____ ____  _______   ______${R}"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "${R_ORG}${B}              | | | |  _ \|  _ \  / \|_   _| ___|/ ___/\ \ / / ___|${R}"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "${R_YEL}${B}              | | | | |_) | | | |/ _ \ | | |  _| \___ \ \ V /\___ \ ${R}"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "${R_GRN}${B}              | |_| |  __/| |_/ / ___ \| | | |___ ___) | | |  ___) |${R}"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "${R_BLU}${B}               \___/|_|   |____/_/   \_\_| |_____|____/  |_| |____/${R}"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo ""; ((CURRENT_LOGO_LINE++)); sleep $tim

    echo -e ""
    echo -e ""
    echo -e ""
    echo -e ""
    # 2. Sub-Header
    echo -e "            ${G}SID SENTINEL: ARCHITECTURE ENFORCEMENT & RISK-AWARE UPDATES${R}"; ((CURRENT_LOGO_LINE++)); sleep $tim

    # 3. IBM Data Box (Clean inner space)
    echo -e "${G}"; ((CURRENT_LOGO_LINE++))
    echo -e "                     _________________________________________"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    / ${C_WARN}_______________________________________${G} \\"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    |${C_WARN}|                                       |${G}|"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    |${C_WARN}|                                       |${G}|"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    |${C_WARN}|                                       |${G}|"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    |${C_WARN}|${G}        [ ${W}SID SENTINEL ACTIVE${G} ]        ${C_WARN}|${G}|"; ((CURRENT_LOGO_LINE++)); sleep $tim
    printf "                    |${C_WARN}|${G}        > DEBIAN_ARCH: ${W}%-9s${G}       ${C_WARN}|${G}|\n" "${ARCH,,}"; ((CURRENT_LOGO_LINE++)); sleep $tim
    printf "                    |${C_WARN}|${G}        > KERNEL: ${W}%-14s${G}       ${C_WARN}|${G}|\n" "${KERNEL}"; ((CURRENT_LOGO_LINE++)); sleep $tim
    printf "                    |${C_WARN}|${G}        > RISK_LVL: ${G}%-11s${G}        ${C_WARN}|${G}|\n" "MONITORING"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    |${C_WARN}|                                       |${G}|"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    |${C_WARN}|                                       |${G}|"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    |${C_WARN}|            ${W}by Sergio Melas${G}            ${C_WARN}|${G}|"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    |${C_WARN}|                                       |${G}|"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    |${C_WARN}|                                       |${G}|"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    |${C_WARN}|_______________________________________|${G}|"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                    \_________________________________________/"; ((CURRENT_LOGO_LINE++)); sleep $tim

    # 4. Keyboard/Base
    echo -e "                    ${G}/_________________________________________\\"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                   /    ${C_WARN}_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _    ${G}\\"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                  /    ${C_WARN}/_/_/_/_/_/_/_|_|_|_|_|_\_\_\_\_\_\_\    ${G}\\"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                 /    ${C_WARN}_/_/_/_/_/_/_|_|_|_|_|_|_|_\_\_\_\_\_\_    ${G}\\"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "                /    ${C_WARN}/SHIFT/_/_/_|_|_|_|_|_|_|_|_|_\_\_\ ENTER\   ${G}\\"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "               /    ${C_WARN}/CTRL/ALT/_/_/________________\_\_\_\<\ V\>\   ${G}\\"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "              /                  _________________                  \\"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "             /                  /                 \                  \\"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "            /__________________/___________________\__________________\\"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "            |_________________________________________________________|"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e "${R}"; ((CURRENT_LOGO_LINE++)); sleep $tim
    echo -e " "; ((CURRENT_LOGO_LINE++))

    # Calculate absolute terminal Y positions after drawing completes
    exec 6<&0; exec 0</dev/tty
    local old_stty=$(stty -g)
    stty raw -echo min 0 time 1
    echo -ne "\033[6n" >/dev/tty
    local pos
    read -r -d R pos
    stty "$old_stty"
    exec 0<&6

    local end_y=${pos#*\[}
    end_y=$((${end_y%%;*} - 1))
    START_Y=$((end_y - CURRENT_LOGO_LINE))

    INIT_SAFE_SLOTS
    start_shine
}

bottom_up_clean() {
    local cols=$(tput cols)
    local lines=$(tput lines)
    local row="" pos=""

    stop_shine
    tput civis

    # 1. Drain pending input
    while read -r -s -t 0.05 -n 10000 _; do :; done 2>/dev/null

    # 2. Query cursor position directly
    if [ -c /dev/tty ]; then
        local old_stty
        old_stty=$(stty -g </dev/tty 2>/dev/null)
        stty raw -echo min 0 time 1 </dev/tty 2>/dev/null
        echo -ne "\033[6n" >/dev/tty
        read -r -d R pos </dev/tty 2>/dev/null
        [ -n "$old_stty" ] && stty "$old_stty" </dev/tty 2>/dev/null
        pos=${pos#*\[}
        row=${pos%%;*}
    fi

    # Fallback: if query failed or row <= 1, wipe full terminal height
    if [[ ! "$row" =~ ^[0-9]+$ ]] || [ "$row" -le 1 ]; then
        row=$lines
    fi

    local current_y=$((row - 1))
    [ "$current_y" -ge "$lines" ] && current_y=$((lines - 1))
    [ "$current_y" -lt 0 ] && current_y=0

    tput ed
    local empty_line=$(printf '%*s' "$cols" "")
    local delay=0.02
    [ "$current_y" -gt 25 ] && delay=0.01

    for ((y=current_y; y>=0; y--)); do
        tput cup $y 0
        echo -n "$empty_line"
        sleep $delay
    done

    tput cup 0 0
    tput cnorm
}

square_clean_up() {
    local cols=$(tput cols)
    local lines=$(tput lines)
    local row col response delay

    stop_shine

    # 1. Flush input buffer
    read -sdR -t 0.05 -n 10000 2>/dev/null

    # 2. Get current cursor row
    echo -ne "\e[6n"
    if read -sdR -t 0.2 response 2>/dev/null; then
        response=${response#*[[}
        row=${response%;*}
    fi

    # Fallback if we can't read cursor position
    if [[ ! "$row" =~ ^[0-9]+$ ]]; then
        row=$lines
    fi

    local current_y=$((row - 1))

    # Hide cursor
    tput civis

    # 3. INSTANTLY clear everything below the cursor
    tput ed

    # 4. Set 0-indexed vertical boundaries (Top and Bottom of active area)
    local y1=0
    local y2=$current_y

    # Pre-generate a full row of spaces for instant line clearing
    local empty_line=$(printf '%*s' "$cols" "")

    # 5. Tuned Delay for Dual-Line Sweeps
    delay=0.04
    if [ "$current_y" -gt 35 ]; then
        delay=0.02
    fi

    # 6. Squeeze Inward toward Center
    while [ $y1 -le $y2 ]; do
        # Clear top line
        tput cup $y1 0
        echo -n "$empty_line"

        # Clear bottom line (if different from top)
        if [ $y1 -lt $y2 ]; then
            tput cup $y2 0
            echo -n "$empty_line"
        fi

        # Move top downward, bottom upward
        ((y1++))
        ((y2--))

        sleep $delay
    done

    # 7. Final clean sweep and cursor restore
    tput clear
    tput cup 0 0
    tput cnorm
}

draw_progress() {
    local width=79

    # Fail-safe: Cap the current step to prevent layout overflow if STEP exceeds TOTAL_STEPS
    local current_step=$STEP
    [ "$current_step" -gt "$TOTAL_STEPS" ] && current_step=$TOTAL_STEPS

    local percent=$(( (current_step * 100) / TOTAL_STEPS ))
    local filled=$(( (current_step * width) / TOTAL_STEPS ))
    local empty=$(( width - filled ))

    # Draw the completed progress bar segments (Green)
    echo -ne "${C_NALA_G}"
    for ((i=0; i<filled; i++)); do echo -n "━"; done

    # Draw the remaining progress bar segments (Red)
    echo -ne "${C_NALA_R}"
    for ((i=0; i<empty; i++)); do echo -n "━"; done

    echo -e "${C_RESET}\n Progress: ${percent}%"
}

draw_header() {
    local title="$1"
    local tip="$2"
    local width=79

    # Correct top bar length math to match the framework columns perfectly
    local title_len=${#title}
    local bar_len=$((width - title_len - 4))
    if [ "$bar_len" -lt 1 ]; then bar_len=1; fi

    echo -ne "${C_BORDER}┏━${C_TEXT}${C_BOLD}${title} ${C_RESET}${C_BORDER}$(printf '━%.0s' $(seq 1 $bar_len))┓\n"
    # Use standard printf padding to enforce exactly 75 characters for the inner text space
    printf "${C_BORDER}┃${C_RESET}  %-75s${C_BORDER}┃\n" "$tip"
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
    if echo "$list" | grep -Ei "gcc-|clang-|binutils|make|dkms|cmake|python3|perl|devscripts" >/dev/null; then
        add_hit "${C_PROMPT}󰅩 Toolchain:${C_RESET} Compilers, runtimes or devscripts. Impacts core ecosystem." 15
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

    # --- 18. Query library transition patterns directly from package list
    local V_CHANGE=$(echo "$list" | grep -oEi "lib(kf[5-9]|qt[5-9]|gnome[0-9]|gtk[3-5]|glib[0-9])" | sort -u | wc -l)
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


    echo -ne "\n ${C_BOLD}TOTAL RISK SCORE:${C_RESET} "

    if [ "$risk_score" -ge 75 ]; then
        echo -e "${C_NALA_R}${risk_score} - CRITICAL${C_RESET} (Override Highly Recommended)"
    elif [ "$risk_score" -ge 45 ]; then
        echo -e "${C_WARN}${risk_score} - HIGH${C_RESET}     (Review Transition Impacts)"
    else
        echo -e "${C_PROMPT}${risk_score} - MODERATE${C_RESET} (Safe to Proceed with Caution)"
    fi

    echo -e " ${C_BOLD}SENTINEL INDEX:${C_RESET}   ${C_WARN}${risk_score}${C_RESET}"
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
draw_separator "Proudly Protecting Your SID Updates"
show_logo
echo -e "${C_PROMPT}Requesting administrator privileges...${C_RESET}"
sudo sh -c 'echo ""; ls' >/dev/null
echo -e "Thanks\n"

# Stop background animation to prevent cursor conflicts with foreground text
stop_shine

bottom_up_clean

draw_progress
draw_header "Initial Check" "Analyzing all package managers..."


# 2.1 PACKAGE MANAGERS INITIAL STATE & APT/NALA TRUTH PROBE
FP_UP=true
SNAP_UP=true

start_spinner "APT/Nala: Updating Repositories"
sudo nala update >/dev/null 2>&1
stop_spinner
echo -e "${C_NALA_G}Done${C_RESET}"

start_spinner "Sentinel: Analyzing Dual-Stage Risks"

# --- STAGE 1: Standard Upgrade Simulation (Conservative Path) ---
SIM_UPGRADE=$(apt-get upgrade -s -o APT::Get::Upgrade-Allow-New=false 2>/dev/null)

UPGRADE_UPGRADES=$(echo "$SIM_UPGRADE" | grep -Ei "upgraded," | sed -E 's/([0-9]+) upgraded.*/\1/' | awk '{print $1}' | tail -n1)
UPGRADE_UPGRADES=${UPGRADE_UPGRADES:-0}

UPGRADE_REMOVALS=$(echo "$SIM_UPGRADE" | grep -Ei "^Remv " | wc -l)
UPGRADE_REMOVALS=${UPGRADE_REMOVALS:-0}

# --- STAGE 2: APT Solver + Orphan Cascade Simulation ---
SIM_OUT=$(apt-get dist-upgrade -s 2>/dev/null)
SIM_AUTOREMOVE=$(apt-get autoremove --purge -s 2>/dev/null)

APT_COUNT=$(echo "$SIM_OUT" | grep -c "^Inst " | awk '{print $1}' | tail -n1)
APT_COUNT=${APT_COUNT:-0}

APT_DIST_REMOVALS=$(echo "$SIM_OUT" | grep -E "^(Remv|Purg) " | awk '{print $2}')
APT_AUTO_REMOVALS=$(echo "$SIM_AUTOREMOVE" | grep -E "^(Remv|Purg) " | awk '{print $2}')

# --- STAGE 3: Nala Probe via Isolated Temp Buffer ---
NALA_TMP=$(mktemp)
if command -v nala &>/dev/null; then
    ( echo "n" | sudo nala full-upgrade --autoremove --purge --no-update > "$NALA_TMP" 2>&1 ) &
    NALA_PID=$!
    while kill -0 "$NALA_PID" 2>/dev/null; do
        sleep 0.1
    done
    wait "$NALA_PID" 2>/dev/null

    NALA_STREAM=$(tr -d '\r' < "$NALA_TMP" | sed $'s/\e\\[[0-9;]*[a-zA-Z]//g')

    NALA_AUTOPURGE=$(echo "$NALA_STREAM" | awk '
        /^[[:space:]]*(Auto-Purging|Purging|Removing)/ { in_section=1; next }
        /^[[:space:]]*(Installing|Upgrading|Kept Back|Summary)/ { in_section=0 }
        in_section && /^[[:space:]]+[a-z0-9]/ && !/Package:/ { print $1 }
    ')

    NALA_SUM_AP=$(echo "$NALA_STREAM" | grep -E "^[[:space:]]*Auto-Purge" | grep -oE "[0-9]+" | head -n1)
    NALA_SUM_P=$(echo "$NALA_STREAM" | grep -E "^[[:space:]]*Purge[[:space:]]" | grep -oE "[0-9]+" | head -n1)
    NALA_TOTAL_PURGE=$(( ${NALA_SUM_AP:-0} + ${NALA_SUM_P:-0} ))
else
    NALA_AUTOPURGE=""
    NALA_TOTAL_PURGE=0
fi
rm -f "$NALA_TMP"

# Stop the spinner only after both APT and Nala probes finish
stop_spinner

# --- Master List & Total Removal Count ---
FULL_REMOVAL_LIST=$(echo -e "${APT_DIST_REMOVALS}\n${APT_AUTO_REMOVALS}\n${NALA_AUTOPURGE}" | sed '/^$/d' | sort -u)
PARSED_COUNT=$(echo "$FULL_REMOVAL_LIST" | grep -v "^$" | wc -l || echo 0)

if [ "${NALA_TOTAL_PURGE:-0}" -gt "$PARSED_COUNT" ]; then
    REMOVAL_COUNT=$NALA_TOTAL_PURGE
else
    REMOVAL_COUNT=$PARSED_COUNT
fi
REMOVAL_COUNT=${REMOVAL_COUNT:-0}

# --- Status Reporting ---
APT_UP=true
if [ "$APT_COUNT" -gt 0 ]; then
    APT_UP=false
    echo -e "${C_WARN}Updates Found ($APT_COUNT)${C_RESET}"

    if [ "$UPGRADE_UPGRADES" -gt 0 ]; then
        echo -e " ${C_PROMPT}󰒓${C_RESET} Safe Path: Up to ${C_NALA_G}${UPGRADE_UPGRADES}${C_RESET} packages available for standard upgrade."
    else
        echo -e " ${C_PROMPT}󰒓${C_RESET} Safe Path: ${C_NALA_R}0${C_RESET} (Full transition required for all pending updates)"
    fi

    if [ "$REMOVAL_COUNT" -gt 0 ]; then
        echo -e " ${C_NALA_R}󰆴${C_RESET} Sentinel Alert: ${C_NALA_R}${REMOVAL_COUNT}${C_RESET} removals/auto-purges detected for full transition."
    fi
else
    echo -e "${C_NALA_G}Up to date${C_RESET}"
fi

# 2.2 FLATPAK (Fixed Execution Flow)
if command -v flatpak &>/dev/null; then
    start_spinner "Flatpak:  Checking Runtimes"

    # 1. Capture the evaluation output into a variable safely
    FP_CHECK=$(echo "n" | sudo flatpak update 2>&1)

    # 2. Kill the spinner engine immediately while the cursor is controlled
    stop_spinner

    # 3. Perform string pattern matching on the isolated variable
    if echo "$FP_CHECK" | grep -iqE "ID|Updating|Installing"; then
        FP_UP=false
        echo -e "${C_WARN}Updates Found${C_RESET}"
    else
        FP_UP=true
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

# --- 2.3.1 Conditional Discovery Wait ---
# Logic: If ANY manager found even one update, we MUST pause.
# We check the actual counts: APT_COUNT, Flatpak (FP_UP), and Snap (SNAP_UP)

if [ "$APT_COUNT" -gt 0 ] || [ "$FP_UP" = "false" ] || [ "$SNAP_UP" = "false" ]; then
    echo -e "\n${C_BORDER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo -ne "${C_WARN}󰋖 Analysis complete. Review findings above.${C_RESET}"

    # Force a small sleep to ensure the UI has finished drawing before the read
    sleep 0.5
    wait_user

    bottom_up_clean
    draw_progress
    draw_header "Sentinel Analysis" "Capturing Deep Risk Telemetry..."
fi

# --- 2.4 SID SENTINEL DATA CAPTURE & FLAGS ---
MAX_DELETIONS=5
MAX_KEPT_BACK=50

# Critical hits check (System Runtimes, Toolchains, Desktop Environments)
if echo "$FULL_REMOVAL_LIST" | grep -qEi "gnome|plasma|kde|xfce|sway|libc6|systemd|xorg|wayland|uim|fcitx|ibus|maliit|webkit|clutter|cheese|perl|python3|binutils|gcc|dpkg|apt|devscripts"; then
    CRITICAL_HIT="true"
else
    CRITICAL_HIT="false"
fi

KEPT_BACK_COUNT=$(echo "$SIM_OUT" | grep "not upgraded" | grep -oEi "[0-9]+ not upgraded" | awk '{print $1}' || echo 0)
KEPT_BACK_COUNT=${KEPT_BACK_COUNT:-0}

# 4. DUAL-STAGE RISK FLAGS (Now fully robust)
UPGRADE_DANGER=false; [ "${UPGRADE_REMOVALS:-0}" -gt 0 ] && UPGRADE_DANGER=true

FULL_DANGER=false
if [ "$REMOVAL_COUNT" -gt "$MAX_DELETIONS" ] || [ "$CRITICAL_HIT" = "true" ] || [ "$KEPT_BACK_COUNT" -gt "$MAX_KEPT_BACK" ]; then
    FULL_DANGER=true
fi

# 6. Optional: Telemetry Capture for the Risk Translator
# Calculates a raw danger score for internal weighting
RAW_RISK_SCORE=0
[ "$REMOVAL_COUNT" -gt 0 ] && ((RAW_RISK_SCORE += REMOVAL_COUNT * 5))
[ "$CRITICAL_HIT" = "true" ] && ((RAW_RISK_SCORE += 50))
[ "$KEPT_BACK_COUNT" -gt 20 ] && ((RAW_RISK_SCORE += 10))

# --- 3.0 INTELLIGENT EMERGENCY BRAKE (SPLIT-PATH) ---

# FAIL-SAFE: Abort if standard upgrade is broken
if [ "$UPGRADE_DANGER" = "true" ]; then
    bottom_up_clean
    draw_progress
    draw_header "!!! CRITICAL BASE FAILURE !!!" "Standard upgrade is attempting removals."
    echo -e "${C_NALA_R}FATAL: Standard 'apt upgrade' is not safe. Aborting.${C_RESET}"
    exit 1
fi

# TRANSITION TRAP: Offer to Mask/Skip the Full-Upgrade
if [ "$FULL_DANGER" = "true" ]; then
    bottom_up_clean
    draw_progress
    draw_header "!!! DANGER DETECTED IN FULL TRANSITION!!!" "Potential System Destruction Found"
    explain_danger "$FULL_REMOVAL_LIST"

    echo -e " ${C_BOLD}Sentinel Risk Index:${C_RESET} ${C_WARN}${RAW_RISK_SCORE}${C_RESET}"

    if [ "$REMOVAL_COUNT" -gt 0 ]; then
        echo -ne "\n${C_NALA_R}${C_BOLD}Technical Removal List (Summary):${C_RESET}\n"
        headshow=8
        echo "$FULL_REMOVAL_LIST" | head -n $headshow | sed 's/^/  - /'
        [ "$REMOVAL_COUNT" -gt $headshow ] && echo -e "  ${C_BORDER}... and $((REMOVAL_COUNT - $headshow)) more.${C_RESET}"
    fi

    echo -ne "\n${C_BOLD}Trigger: ${C_RESET}"
    [ "$CRITICAL_HIT" = "true" ] && echo -e "${C_NALA_R}Critical component hit!${C_RESET}" || echo -e "${C_WARN}Threshold exceeded.${C_RESET}"

    # THE MASK CHOICE
    echo -ne "\n${C_PROMPT}Standard updates are safe. Override full Upgrade ? [Y/n]: ${C_RESET}"
    read -r danger_resp
    if [[ ! "$danger_resp" =~ ^[Nn]$ ]]; then
        SKIP_FULL_UPGRADE=true
        bottom_up_clean
        draw_progress
        draw_header "Sentinel Shield Engaged" "Safe updates enabled, dangerous transitions overridden."
        echo -e "\n ${C_WARN}󰜺${C_RESET} High-risk 'dist-upgrade' transitions will be skipped."
        wait_user
        bottom_up_clean
    else
        SKIP_FULL_UPGRADE=false
        echo -e "\n ${C_NALA_R}󰜺${C_RESET} Risk accepted. Proceeding with full risk."
    fi
fi

# 3.0 Proceed logic
if [ "$APT_UP" = "true" ] && [ "$FP_UP" = "true" ] && [ "$SNAP_UP" = "true" ]; then
    ((STEP+=6))
    draw_header "Status" "System is already fully up to date."
    wait_user
else
    # FIXED: Check if the user chose to skip high-risk full-upgrade transitions
    if [ "$SKIP_FULL_UPGRADE" = "true" ] && [ "$FP_UP" = "true" ] && [ "$SNAP_UP" = "true" ]; then
        draw_header "Status" "APT Upgrade Skipped. No other updates pending."
        ((STEP+=4))
        wait_user
    else
        # 3.1 Standard Upgrade - Show only what is actually pending
        if [ "$FULL_DANGER" = "false" ]; then
            if [ "$REMOVAL_COUNT" -gt 0 ]; then
                echo -e "  ${C_PROMPT}󰄬 Low-Risk Transition:${C_RESET} ${C_WARN}${REMOVAL_COUNT}${C_RESET} removal(s) detected (within threshold of ${MAX_DELETIONS}).\n"
            else
                echo -e "  ${C_NALA_G}󰄬 No risk found.${C_RESET}\n"
            fi
        fi
        draw_header "Update Pending" "Available Upgrades"

        [ "$APT_UP" = "false" ] && echo -e " ${C_WARN}󰏓${C_RESET} APT Packages"
        [ "$FP_UP" = "false" ] && echo -e " ${C_WARN}󰏓${C_RESET} Flatpak Runtimes"
        [ "$SNAP_UP" = "false" ] && echo -e " ${C_WARN}󰏓${C_RESET} Snap Daemons"

        wait_user
        bottom_up_clean
        draw_progress
        draw_header "Update Pending" "Performing standard package upgrade"

        # Stage 1: Safe Upgrade (standard packages only)
        if [ "$APT_UP" = "false" ]; then
            draw_header "Stage 1: Standard Upgrade" "Applying safe, non-removal package updates"
            sudo nala upgrade --autoremove --install-recommends --fix-broken --purge --no-update
        fi
        ((STEP++))

        # Stage 2: Sid Full-Upgrade (Triggers when transitions/removals like libavcodec are needed)
        if [ "$SKIP_FULL_UPGRADE" != "true" ] && [ "$APT_UP" = "false" ]; then
            bottom_up_clean
            draw_progress
            draw_header "Stage 2: Sid Full-Upgrade" "Intelligent package transitions (Dist-Upgrade)"

            # If Stage 1 held packages back due to required removals, default prompt to YES ([Y/n])
            if [ "$REMOVAL_COUNT" -gt 0 ] || [ "$UPGRADE_UPGRADES" -eq 0 ]; then
                echo -e "${C_WARN}Notice:${C_RESET} Package transitions/removals are required to complete all updates."
                echo -ne "\n${C_PROMPT}Run nala full-upgrade now? [Y/n]${C_RESET} "
                read -r full_resp

                if [[ ! "$full_resp" =~ ^[Nn]$ ]]; then
                    sudo nala full-upgrade --autoremove --purge --no-update
                fi
            else
                echo -ne "\n${C_PROMPT}Run nala full-upgrade? [y/N]${C_RESET} "
                read -r full_resp
                if [[ "$full_resp" =~ ^[Yy]$ ]]; then
                    sudo nala full-upgrade --autoremove --purge --no-update
                fi
            fi
        fi
        ((STEP++))

        # 3.3 Flatpak Update
        bottom_up_clean
        draw_progress
        draw_header "Flatpak" "Updating Flatpak runtimes and apps"
        if [ "$FP_UP" = "false" ]; then
            sudo flatpak update -y
        fi
        ((STEP++))

        wait_user

        # 3.4 Snap Update
        bottom_up_clean
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
bottom_up_clean
draw_progress
draw_header "Maintenance" "Final System Optimization"
echo -ne "\n${C_PROMPT}Run deep system cleanup? [y/N]${C_RESET} "
read -r resp
if [[ ! "$resp" =~ ^[Yy]$ ]]; then
    ((STEP+=5))
    echo -e "${C_WARN}Cleanup skipped by user.${C_RESET}"
else
    ((STEP++))

    # 4.1 Precision Kernel Modules Cleanup
    bottom_up_clean
    draw_progress
    draw_header "Cleanup 1/5" "Analyzing Orphaned Kernel Modules"

    pre_k=$(du -sb /lib/modules 2>/dev/null | cut -f1)
    pre_k=${pre_k:-0}
    RUNNING_K=$(uname -r)

    echo -e "${C_BORDER}Kernel Verification Phase:${C_RESET}"
    echo -e "  Active Kernel: ${C_PROMPT}$RUNNING_K${C_RESET}"
    INSTALLED_KS=$(dpkg -l 'linux-image-*' 2>/dev/null | grep '^ii' | awk '{print $2}' | sed 's/linux-image-//g')

    # FIXED: Enable nullglob locally to ensure empty directory scopes do not pass literal glob characters
    shopt -s nullglob
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
        # 1. Check dpkg registered kernels
        for inst_k in $INSTALLED_KS; do
            if [[ "$k_ver" == "$inst_k"* ]]; then MATCH_FOUND=true; break; fi
        done

        # 2. Check boot partition for custom/compiled kernels and initrds
        if [ -f "/boot/vmlinuz-$k_ver" ] || [ -f "/boot/initrd.img-$k_ver" ] || [ -f "/boot/config-$k_ver" ]; then
            MATCH_FOUND=true
        fi

        if [ "$MATCH_FOUND" = true ]; then
            echo -e "  [${C_BORDER}KEEP${C_RESET}] Registered: $k_ver"
        else
            echo -e "  [${C_WARN}PURGE${C_RESET}] Orphaned: $k_ver (System Load: $LOAD_K)"
            sudo rm -rf "$mod_dir"
            # Verification: Did it actually delete?
            [ ! -d "$mod_dir" ] && echo -e "      -> ${C_NALA_G}Verified Success${C_RESET}" || echo -e "      -> ${C_NALA_R}Removal Failed${C_RESET}"
        fi
    done
    shopt -u nullglob  # FIXED: flag

    post_k=$(du -sb /lib/modules 2>/dev/null | cut -f1)
    post_k=${post_k:-0}
    diff_k=$(( pre_k - post_k ))
    [ "$diff_k" -gt 0 ] && TOTAL_FREED=$(( TOTAL_FREED + diff_k ))
    wait_user

    # 4.2 Cache Maintenance (Nala & APT - Fixed Precision Analytics)
    bottom_up_clean
    draw_progress
    draw_header "Cleanup 2/5" "Package Cache Purge"

    # Track the total raw available bytes on the root partition before purging
    pre_space=$(df -B1 / | awk 'NR==2 {print $4}')

    echo -e "${C_BORDER}Clearing Nala & APT caches...${C_RESET}"
    sudo nala clean
    sudo apt-get autoclean -y
    sudo apt-get autoremove --purge -y

    # Track the total raw available bytes on the root partition after purging
    post_space=$(df -B1 / | awk 'NR==2 {print $4}')

    # True metric recovery is calculated as: post_space - pre_space
    diff_c=$(( post_space - pre_space ))

    # If blocks were successfully freed, append the delta to the global tracker
    [ "$diff_c" -gt 0 ] && TOTAL_FREED=$(( TOTAL_FREED + diff_c ))
    wait_user

    # 4.3 Residual Configs (Deep Scan)
    bottom_up_clean
    draw_progress
    draw_header "Cleanup 3/5" "Residual Configuration Files"

    purgestr=$(COLUMNS=200 dpkg -l | grep "^rc" | awk '{print $2}')
    if [ -n "$purgestr" ]; then
        echo -e "${C_WARN}Found leftover configs for:${C_RESET}"
        echo "$purgestr" | sed 's/^/  - /'

        # Use xargs to safely feed the clean whitespace-delimited arguments to dpkg
        echo "$purgestr" | xargs sudo dpkg --purge
    else
        echo -e "${C_PROMPT}Success:${C_RESET} No residual configs detected."
    fi
    wait_user

    # 4.4 Multi-Point Journal Vacuuming
    bottom_up_clean
    draw_progress
    draw_header "Cleanup 4/5" "Log Rotation & Journal Vacuuming"
    pre_l=$(du -sb /var/log/journal 2>/dev/null | cut -f1 || echo 0)

    echo -e "${C_BORDER}Vacuuming Systemd Journal (Retention: 7 days / 100M)...${C_RESET}"
    sudo journalctl --vacuum-time=7d
    sudo journalctl --vacuum-size=100M

    post_l=$(du -sb /var/log/journal 2>/dev/null | cut -f1 || echo 0)
    diff_l=$(( pre_l - post_l ))
    [ "$diff_l" -gt 0 ] && TOTAL_FREED=$(( TOTAL_FREED + diff_l ))
    draw_separator "Journal Cleaned"
    wait_user

    # 4.5 DKMS Depth Check (Precision Verification)
    bottom_up_clean
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
bottom_up_clean
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
bottom_up_clean
STEP=$TOTAL_STEPS
draw_progress

# 1. Print the static logo
show_logo
sleep 10

# 2. Stop the star daemon immediately so no subshell hangs in the background
stop_shine
draw_header "Goodbye" "Process complete."
sleep 3

# 3. Clean up terminal screen
square_clean_up

# 4. Restore cursor and exit cleanly
tput cnorm
#kill $(ps -ho ppid -p $(ps -ho ppid -p $$)) 2>/dev/null
exit 0
