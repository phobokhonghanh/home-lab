#!/bin/bash
# deploy.sh
# Purpose: Deploy Airflow Stack

GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${GREEN}[!] Syncing Code and Deploying Airflow Stack${RESET}"
echo -e "${YELLOW}[!] Sync Target: airflow_managers, airflow_workers${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/airflow/deploy.yml -i inventory/home-lab.ini
