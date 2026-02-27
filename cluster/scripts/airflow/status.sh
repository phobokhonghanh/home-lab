#!/bin/bash
# status.sh
# Purpose: Check Airflow Stack status

BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] Checking Airflow Stack Status${RESET}"

ssh root@100.122.90.44 "docker stack ps airflow"
