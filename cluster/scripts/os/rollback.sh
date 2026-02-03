#!/bin/bash
# rollback.sh
# Purpose: Rollback OS Configuration settings

BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] Rollback OS Configuration${RESET}"

TARGET=${1:-os}

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/os/rollback.yml -i inventory/home-lab.ini --limit "$TARGET"
