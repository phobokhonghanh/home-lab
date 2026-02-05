#!/bin/bash
# init.sh
# Purpose: Initialize Swarm Manager

GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${GREEN}[!] Initialize Swarm Manager${RESET}"
echo -e "${YELLOW}[!] Target: manager (node04)${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/swarm/init.yml -i inventory/home-lab.ini
