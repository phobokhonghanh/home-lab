#!/bin/bash

# ==============================================================================
# System Configuration Rollback
# ==============================================================================

# Initializes terminal color codes.
init_colors() {
    GREEN="\033[32m"
    YELLOW="\033[33m"
    RED="\033[31m"
    RESET="\033[0m"
}

# Logs an informational message.
#
# @param $1 The message to log.
log_info() { printf "${GREEN}[INFO] %s${RESET}\n" "$1"; }

# Logs a warning message.
#
# @param $1 The message to log.
log_warn() { printf "${YELLOW}[WARN] %s${RESET}\n" "$1"; }

# Logs an error message.
#
# @param $1 The message to log.
log_err()  { printf "${RED}[ERROR] %s${RESET}\n" "$1"; }

# Ensures script is run with root/sudo privileges.
#
# @return Exits with 1 if not running as root.
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_err "Please run this script with sudo"
        exit 1
    fi
}

# Restores a file from its .bak counterpart.
#
# @param $1 Path to the file to restore.
restore_file() {
    local file=$1
    if [ -f "${file}.bak" ]; then
        log_info "Restoring ${file}..."
        mv "${file}.bak" "$file"
        return 0
    else
        log_warn "Backup for ${file} not found"
        return 1
    fi
}

# Restores original systemd-logind config and restarts the service.
restore_logind() {
    local conf="/etc/systemd/logind.conf"
    if restore_file "$conf"; then
        systemctl restart systemd-logind
        log_info "Original logind configuration restored"
    fi
}

# Re-enables masked systemd sleep/suspend targets.
unmask_sleep_targets() {
    log_info "Re-enabling sleep/suspend modes..."
    systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
    log_info "Sleep modes unmasked"
}

# Restores Wi-Fi power save settings.
restore_wifi() {
    local nm_conf="/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf"
    if restore_file "$nm_conf"; then
        systemctl restart NetworkManager
        log_info "Wi-Fi settings restored via NetworkManager"
    elif command -v iw &>/dev/null; then
        local interface
        interface=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)
        if [ ! -z "$interface" ]; then
            iw dev "$interface" set power_save on
            log_info "Wi-Fi Power Save re-enabled on interface $interface"
        fi
    fi
}

# Orchestrates rollback of all configurations.
#
# @param $@ Array of arguments passed to script.
main() {
    printf "\n------------------------------------------------------------------------------------\n"
    init_colors
    check_root
    restore_logind
    unmask_sleep_targets
    restore_wifi
    printf "\n------------------------------------------------------------------------------------\n"
}

main "$@"
