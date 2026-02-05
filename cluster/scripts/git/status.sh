#!/bin/bash
# status.sh
# Purpose: Check Git repositories status (branches, commits, modifications)

GREEN="\033[32m"
RESET="\033[0m"

TARGET=${1:-git_hosts}

echo -e "${GREEN}[!] Checking Git Repositories Status${RESET}"
echo -e "${GREEN}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/git/status.yml -i inventory/home-lab.ini -e "target=$TARGET"
