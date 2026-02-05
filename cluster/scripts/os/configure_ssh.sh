#!/bin/bash
# configure_ssh.sh
# Purpose: Configure SSH Security

BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-os}

echo -e "${BLUE}[!] Configure SSH Security${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/os/configure_ssh.yml -i inventory/home-lab.ini -e "target=$TARGET"
