#!/bin/bash
# status.sh
# Purpose: Check Docker status (version, service, containers, images, disk)

GREEN="\033[32m"
RESET="\033[0m"

TARGET=${1:-docker}

echo -e "${GREEN}[!] Checking Docker Status${RESET}"
echo -e "${GREEN}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/docker/status.yml -i inventory/home-lab.ini -e "target=$TARGET"
