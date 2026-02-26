#!/bin/bash
# status.sh
# Purpose: Check Spark Stack Status

GREEN="\033[32m"
RESET="\033[0m"

echo -e "${GREEN}[!] Checking Spark Stack Status${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/spark/status.yml -i inventory/home-lab.ini
