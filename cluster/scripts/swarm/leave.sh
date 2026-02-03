#!/bin/bash
# leave.sh
# Purpose: Force nodes to leave Docker Swarm

BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] Leave Docker Swarm${RESET}"

TARGET=${1:-all}

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/swarm/leave.yml -i inventory/home-lab.ini --limit "$TARGET"
