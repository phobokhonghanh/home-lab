#!/bin/bash
# remove.sh
# Purpose: Remove specific nodes from Spark Cluster

RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-remove_workers}

echo -e "${RED}[!] Remove Spark Nodes${RESET}"
echo -e "${YELLOW}[!] Target: ${TARGET}${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/spark/remove.yml -i inventory/home-lab.ini -e "target=${TARGET}"
