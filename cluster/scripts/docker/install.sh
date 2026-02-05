#!/bin/bash
# install.sh
# Purpose: Install Docker via Docker Role

BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-docker}

echo -e "${BLUE}[!] Install Docker${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/docker/setup.yml -i inventory/home-lab.ini -e "target=$TARGET"
