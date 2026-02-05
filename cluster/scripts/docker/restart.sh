#!/bin/bash
# restart.sh
# Purpose: Restart Docker service

BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-docker}

echo -e "${BLUE}[!] Restart Docker Service${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/docker/restart.yml -i inventory/home-lab.ini -e "target=$TARGET"
