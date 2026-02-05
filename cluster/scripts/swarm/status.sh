#!/bin/bash
# status.sh
# Purpose: Check Docker Swarm Cluster and Service Status

GREEN="\033[32m"
RESET="\033[0m"

echo -e "${GREEN}[!] Fetching Swarm Cluster Status...${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/swarm/status.yml -i inventory/home-lab.ini
