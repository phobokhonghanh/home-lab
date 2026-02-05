#!/bin/bash
# pull.sh
# Purpose: Pull code from Git repositories

BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-git_hosts}

echo -e "${BLUE}[!] Pull Git Repositories${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/git/pull.yml -i inventory/home-lab.ini -e "target=$TARGET"
