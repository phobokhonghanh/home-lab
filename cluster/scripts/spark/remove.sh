#!/bin/bash
# remove.sh
# Purpose: Remove Spark Stack from Swarm

RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}[!] Remove Spark Stack${RESET}"
echo -e "${YELLOW}[!] Target: spark_managers${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/spark/remove.yml -i inventory/home-lab.ini
