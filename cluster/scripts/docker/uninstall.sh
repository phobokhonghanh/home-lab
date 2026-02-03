#!/bin/bash
# uninstall.sh
# Purpose: Uninstall Docker via Docker Role

BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] Uninstall Docker${RESET}"

TARGET=${1:-docker}

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/docker/uninstall.yml -i inventory/home-lab.ini --limit "$TARGET"
