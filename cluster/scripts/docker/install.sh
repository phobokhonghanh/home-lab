#!/bin/bash
# install.sh
# Purpose: Install Docker via Docker Role

BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] Install Docker${RESET}"

TARGET=${1:-docker}

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/docker/setup.yml -i inventory/home-lab.ini --limit "$TARGET"
