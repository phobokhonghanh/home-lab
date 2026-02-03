#!/bin/bash
# configure_ssh.sh
# Purpose: Configure SSH Security via OS Role

BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] Configure SSH Security${RESET}"

TARGET=${1:-all}

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/os/setup.yml -i inventory/home-lab.ini --limit "$TARGET" --tags ssh
