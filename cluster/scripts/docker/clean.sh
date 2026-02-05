#!/bin/bash
# clean.sh
# Purpose: Clean Docker resources via Docker Role

BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-docker}

echo -e "${BLUE}[!] Clean Docker Resources${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/docker/clean.yml -i inventory/home-lab.ini -e "target=$TARGET"
