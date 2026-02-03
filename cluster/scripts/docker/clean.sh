#!/bin/bash
# clean.sh
# Purpose: Clean Docker resources via Docker Role

BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] Clean Docker Resources${RESET}"

TARGET=${1:-docker}

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/docker/cleanup.yml -i inventory/home-lab.ini --limit "$TARGET"
