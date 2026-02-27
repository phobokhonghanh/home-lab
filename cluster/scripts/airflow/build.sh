#!/bin/bash
# build.sh
# Purpose: Build Airflow Custom Image

GREEN="\033[32m"
RESET="\033[0m"

echo -e "${GREEN}[!] Building Airflow Custom Image on Nodes${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/airflow/build.yml -i inventory/home-lab.ini
