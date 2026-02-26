#!/bin/bash
# deploy.sh
# Purpose: Deploy Spark Stack and setup new nodes

GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${GREEN}[!] Syncing Code and Deploying Spark Stack${RESET}"
echo -e "${YELLOW}[!] Sync Target: spark_clusters${RESET}"
echo -e "${YELLOW}[!] New Nodes Target: add_workers${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/spark/deploy.yml -i inventory/home-lab.ini
