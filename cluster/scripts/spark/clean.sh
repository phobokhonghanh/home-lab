#!/bin/bash
# clean.sh
# Purpose: Total destruction and cleanup of the Spark Cluster

RED="\033[31m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${RED}${BOLD}[!] WARNING: NUCLEAR CLEANUP INITIATED [!]${RESET}"
echo -e "${RED}[!] This will remove the stack, all files, and prune all images across the cluster.${RESET}"
read -p "Are you absolutely sure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Cleanup aborted."
    exit 1
fi

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/spark/clean.yml -i inventory/home-lab.ini
