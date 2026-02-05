#!/bin/bash
# remove.sh
# Purpose: Remove nodes from Swarm (Leave + Force Remove)

RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-remove_workers}

echo -e "${RED}[!] Remove Nodes from Swarm${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"
echo -e "${YELLOW}[!] This triggers 'swarm leave' on target and 'node rm' on manager${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/swarm/remove.yml -i inventory/home-lab.ini -e "target=$TARGET"
