#!/bin/bash

# ==============================================================================
# Server SSH Setup (User + Root + Hosts)
# ==============================================================================

# Initializes color constants.
init_colors() {
    GREEN="\033[32m"
    YELLOW="\033[33m"
    RED="\033[31m"
    BLUE="\033[34m"
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

# Prints script usage information.
usage() {
    printf "${BLUE}Usage:${RESET} %s [user@ip] [hostname]\n" "$0"
    printf "Example: %s worker3@192.168.2.69 worker3\n" "$0"
    exit 1
}

# Checks if a public key exists on the local machine.
#
# @return Exits with 1 if no public key is found.
check_pub_key() {
    PUB_KEY=$(ls ~/.ssh/id_*.pub 2>/dev/null | head -n 1)
    if [ -z "$PUB_KEY" ]; then
        log_err "No public key found in ~/.ssh/. Generate one using 'ssh-keygen'."
        exit 1
    fi
}

# Updates the local /etc/hosts file with the remote server's IP and hostname.
#
# @param $1 Remote IP address.
# @param $2 Remote hostname.
update_hosts() {
    local ip=$1
    local hostname=$2
    log_info "Updating /etc/hosts for $hostname ($ip)..."
    if grep -qE "\s$hostname(\s|$)" /etc/hosts || grep -q "^$ip\s" /etc/hosts; then
        log_warn "Host or IP already exists in /etc/hosts. Skipping update."
    else
        echo -e "$ip\t$hostname" | sudo tee -a /etc/hosts > /dev/null
        log_info "Added '$ip $hostname' to /etc/hosts."
    fi
}

# Copies the local public key to the remote user for passwordless SSH.
#
# @param $1 Target (user@ip).
setup_user_ssh() {
    local target=$1
    log_info "Checking SSH access to $target..."
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$target" "exit" &>/dev/null; then
        log_info "SSH access to $target already authorized."
    else
        log_warn "No passwordless access. Running ssh-copy-id..."
        ssh-copy-id "$target" || { log_err "Failed to copy key to $target."; exit 1; }
    fi
}

# Inspects remote sshd_config for PermitRootLogin status.
#
# @param $1 Target (user@ip).
check_remote_config() {
    local target=$1
    log_info "Verifying remote SSH configuration (PermitRootLogin)..."

    local config
    config=$(ssh "$target" "sudo grep '^PermitRootLogin' /etc/ssh/sshd_config" 2>/dev/null)
    if [ -z "$config" ]; then
        config="Not found (defaults to prohibit-password)"
    fi

    log_info "Remote PermitRootLogin: $config"
    if [[ "$config" == *"no"* ]]; then
        log_warn "PermitRootLogin is set to 'no'. Root SSH will fail even with a key."
        log_warn "Please change it to 'prohibit-password' or 'yes' in /etc/ssh/sshd_config and restart sshd."
    fi
}

# Authorizes the user's public key for the remote root account using sudo.
#
# @param $1 Target (user@ip).
upgrade_root_ssh() {
    local user_target=$1
    local ip
    ip=$(echo "$user_target" | cut -d'@' -f2)
    local root_target="root@$ip"
    local pub_key_content
    pub_key_content=$(cat "$PUB_KEY")

    log_info "Checking direct root access to $ip..."
    # Always attempt to push the key unless we can definitely log in as root
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$root_target" "exit" &>/dev/null; then
        log_info "Root access already authorized via SSH key."
    else
        log_warn "No direct root access. Pushing key via $user_target (requires sudo)..."
        local remote_cmd="sudo mkdir -p /root/.ssh && \
                         sudo chmod 700 /root/.ssh && \
                         echo '$pub_key_content' | sudo tee -a /root/.ssh/authorized_keys > /dev/null && \
                         sudo chmod 600 /root/.ssh/authorized_keys"

        if ssh -t "$user_target" "$remote_cmd"; then
            log_info "Root authorized_keys updated."
            check_remote_config "$user_target"
        else
            log_err "Failed to update root authorized_keys. Check user sudo privileges."
        fi
    fi
}

# Main entry point for SSH orchestration.
#
# @param $@ Array of arguments passed to script.
main() {
    printf "\n------------------------------------------------------------------------------------\n"
    init_colors
    if [ $# -ne 2 ]; then usage; fi

    local target=$1
    local hostname=$2
    local ip
    ip=$(echo "$target" | cut -d'@' -f2)
    check_pub_key
    update_hosts "$ip" "$hostname"
    setup_user_ssh "$target"
    upgrade_root_ssh "$target"

    printf "Try: ${BLUE}ssh root@%s${RESET} or ${BLUE}ssh root@%s${RESET}\n" "$hostname" "$ip"
    printf "\n------------------------------------------------------------------------------------\n"
}

main "$@"
