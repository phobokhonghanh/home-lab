#!/bin/bash
# deploy.sh
# Purpose: Deploy Spark Stack to Swarm

GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${GREEN}[!] Deploy Spark Stack${RESET}"
echo -e "${YELLOW}[!] Target: spark_managers${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/spark/deploy.yml -i inventory/home-lab.ini
