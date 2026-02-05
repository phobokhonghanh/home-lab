#!/bin/bash
# rollback.sh
# Purpose: Rollback OS Configuration settings

BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-os}

echo -e "${BLUE}[!] Rollback OS Configuration${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/os/rollback.yml -i inventory/home-lab.ini -e "target=$TARGET"
