#!/bin/bash
# remove.sh
# Purpose: Remove Airflow Stack

RED="\033[31m"
RESET="\033[0m"

echo -e "${RED}[!] Removing Airflow Stack${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/airflow/remove.yml -i inventory/home-lab.ini
