#!/bin/bash

# ==============================================================================
# Environment Setup for Server Laptop
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

# Installs required packages using apt or dnf depending on the OS.
install_packages() {
    log_info "Checking and installing required packages..."
    local packages=("lm-sensors" "bc" "iw" "net-tools" "openssh-server" "openssh-client" "curl")

    if command -v apt &>/dev/null; then
        apt update -y
        for pkg in "${packages[@]}"; do
            if ! dpkg -l | grep -q "^ii  $pkg "; then
                log_info "Installing $pkg..."
                apt install -y "$pkg"
            else
                log_info "$pkg is already installed"
            fi
        done
    elif command -v dnf &>/dev/null; then
        for pkg in "${packages[@]}"; do
            if ! rpm -q "$pkg" &>/dev/null; then
                log_info "Installing $pkg..."
                dnf install -y "$pkg"
            else
                log_info "$pkg is already installed"
            fi
        done
    else
        log_err "System does not support apt or dnf. Please install manually: ${packages[*]}"
        exit 1
    fi
}

# Configures and starts/enables the SSH service.
config_ssh() {
    log_info "Configuring SSH service..."
    if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
        log_info "SSH service is already running"
    else
        log_warn "Starting SSH service..."
        systemctl enable --now ssh 2>/dev/null || systemctl enable --now sshd 2>/dev/null
    fi
}

# Runs sensors-detect automatically to configure lm-sensors.
config_sensors() {
    if command -v sensors-detect &>/dev/null; then
        log_info "Automatically configuring sensors..."
        yes | sensors-detect &>/dev/null
    fi
}

# Entry point for environment setup.
#
# @param $@ Array of arguments passed to script.
main() {
    printf "\n------------------------------------------------------------------------------------\n"
    init_colors
    check_root
    install_packages
    config_ssh
    config_sensors
    printf "\n------------------------------------------------------------------------------------\n"

}

main "$@"
