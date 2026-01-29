#!/bin/bash
# 02-install-requirements.sh
# Purpose: Step 2 - Install System Dependencies
# Usage: ./02-install-requirements.sh

GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] SETUP STEP 2: Installing Basic Requirements${RESET}"
echo "Installing tools like curl, git, htop, ntp, sensors..."

# Allow targeting a specific host/group (default to 'all')
TARGET=${1:-all}

echo -e "${BLUE}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/.." || exit
ansible-playbook playbooks/install-tools.yml -i inventory/home-lab.ini --limit "$TARGET"

echo -e "${GREEN}[OK] Step 2 Complete. Nodes are ready for configuration.${RESET}"
