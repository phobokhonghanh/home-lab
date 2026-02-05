#!/bin/bash
# configure_power.sh
# Purpose: Configure Power Management

BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-os}

echo -e "${BLUE}[!] Configure Power Management${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/os/configure_power.yml -i inventory/home-lab.ini -e "target=$TARGET"
