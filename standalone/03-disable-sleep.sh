#!/bin/bash

# ==============================================================================
# Configuration (Disable Sleep)
# ==============================================================================

# Initializes terminal color codes for logging.
init_colors() {
    GREEN="\033[32m"
    YELLOW="\033[33m"
    RED="\033[31m"
    RESET="\033[0m"
}

# Logs an informational message in green.
#
# @param $1 The message to log.
log_info() { printf "${GREEN}[INFO] %s${RESET}\n" "$1"; }

# Logs a warning message in yellow.
#
# @param $1 The message to log.
log_warn() { printf "${YELLOW}[WARN] %s${RESET}\n" "$1"; }

# Logs an error message in red.
#
# @param $1 The message to log.
log_err()  { printf "${RED}[ERROR] %s${RESET}\n" "$1"; }

# Checks if the script is running with root privileges.
#
# @return Exits with 1 if not running as root.
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_err "Please run this script with sudo"
        exit 1
    fi
}

# Creates a backup of the specified file with .bak extension if it doesn't exist.
#
# @param $1 Path to the file to backup.
backup_file() {
    local file=$1
    if [ ! -f "$file" ]; then
        return 0
    fi
    if [ ! -f "${file}.bak" ]; then
        log_info "Creating backup: ${file}.bak"
        cp "$file" "${file}.bak"
    else
        log_info "Backup already exists: ${file}.bak"
    fi
}

# Configures systemd-logind to ignore lid switch events (keeping server awake).
config_logind() {
    log_info "Configuring systemd-logind..."
    local conf="/etc/systemd/logind.conf"

    backup_file "$conf"

    sed -i 's/^[#]*HandleLidSwitch=.*/HandleLidSwitch=ignore/' $conf
    sed -i 's/^[#]*HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' $conf
    sed -i 's/^[#]*HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' $conf

    if systemctl restart systemd-logind; then
        log_info "systemd-logind restarted successfully"
    else
        log_err "Failed to restart systemd-logind"
    fi
}

# Masks systemd targets related to sleep, suspend, and hibernation.
mask_sleep_targets() {
    log_info "Disabling sleep/suspend/hibernate targets..."
    systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
    log_info "Sleep modes locked"
}

# Disables Wi-Fi power management to prevent network drops.
disable_wifi_powersave() {
    log_info "Disabling Wi-Fi Power Management..."
    local nm_conf="/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf"

    if [ -f "$nm_conf" ]; then
        backup_file "$nm_conf"
        sed -i 's/wifi.powersave = .*/wifi.powersave = 2/' "$nm_conf"
        systemctl restart NetworkManager
        log_info "Wi-Fi Power Management disabled via NetworkManager"
    elif command -v iw &>/dev/null; then
        local interface
        interface=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)
        if [ ! -z "$interface" ]; then
            iw dev "$interface" set power_save off
            log_info "Wi-Fi Power Save disabled on interface $interface"
        fi
    fi
}

# Main entry point for the sleep-disabling configuration.
#
# @param $@ Array of arguments passed to script.
main() {
    printf "\n------------------------------------------------------------------------------------\n"
    init_colors
    check_root
    config_logind
    mask_sleep_targets
    disable_wifi_powersave
    printf "\n------------------------------------------------------------------------------------\n"
}

main "$@"
