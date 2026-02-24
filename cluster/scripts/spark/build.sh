#!/bin/bash
# build.sh
# Purpose: Build Spark Docker Images for new/updated workers

BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${BLUE}[!] Build Spark Docker Images${RESET}"
echo -e "${YELLOW}[!] Source Group: add_workers${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/spark/build.yml -i inventory/home-lab.ini
