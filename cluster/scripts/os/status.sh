#!/bin/bash
# status.sh
# Purpose: Check OS configuration status (packages, SSH, power, timezone)

GREEN="\033[32m"
RESET="\033[0m"

TARGET=${1:-os}

echo -e "${GREEN}[!] Checking OS Configuration Status${RESET}"
echo -e "${GREEN}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/os/status.yml -i inventory/home-lab.ini -e "target=$TARGET"
