#!/bin/bash
# setup.sh
# Purpose: Setup Docker Swarm Cluster

BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] Setup Docker Swarm${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/swarm/setup.yml -i inventory/home-lab.ini
