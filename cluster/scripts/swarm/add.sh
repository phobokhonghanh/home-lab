#!/bin/bash
# join.sh
# Purpose: Join Workers to Swarm

GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-add_workers}

echo -e "${GREEN}[!] Add Workers to Swarm${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/swarm/add.yml -i inventory/home-lab.ini -e "target=$TARGET"
