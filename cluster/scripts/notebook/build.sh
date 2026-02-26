#!/bin/bash
# build.sh
# Purpose: Build Jupyter Lab Docker Image

BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${BLUE}[!] Build Jupyter Lab Docker Image${RESET}"
echo -e "${YELLOW}[!] Source Group: notebook_managers${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/notebook/build.yml -i inventory/home-lab.ini
