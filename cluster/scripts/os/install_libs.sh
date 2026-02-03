#!/bin/bash
# install_libs.sh
# Purpose: Install System Dependencies (Libs) via OS Role

GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] Install Libs Module${RESET}"

# Allow targeting a specific host/group (default to 'all')
TARGET=${1:-all}

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/os/setup.yml -i inventory/home-lab.ini --limit "$TARGET" --tags libs
