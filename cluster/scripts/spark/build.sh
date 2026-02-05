#!/bin/bash
# build.sh
# Purpose: Build Spark Docker Images

BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

TARGET=${1:-spark_clusters}

echo -e "${BLUE}[!] Build Spark Docker Images${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/spark/build.yml -i inventory/home-lab.ini -e "target=$TARGET"
