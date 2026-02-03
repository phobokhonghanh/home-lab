#!/bin/bash
# pull_code.sh
# Purpose: Pull git repositories via Git Role

BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] Pull Git Repositories${RESET}"

TARGET=${1:-git_hosts}

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/git/setup.yml -i inventory/home-lab.ini --limit "$TARGET"
