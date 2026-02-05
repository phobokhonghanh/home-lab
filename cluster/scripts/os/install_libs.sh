#!/bin/bash
# install_libs.sh
# Purpose: Install System Dependencies

BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-os}

echo -e "${BLUE}[!] Install System Libraries${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/os/install_libs.yml -i inventory/home-lab.ini -e "target=$TARGET"
