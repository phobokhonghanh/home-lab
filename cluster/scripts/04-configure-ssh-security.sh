#!/bin/bash
# 04-configure-ssh-security.sh
# Purpose: Step 4 - Harden SSH Security
# Usage: ./04-configure-ssh-security.sh

GREEN="\033[32m"
RED="\033[31m"
BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] SETUP STEP 4: Configuring SSH Security${RESET}"
echo -e "${RED}[WARNING] This will modify sshd_config and restart SSH.${RESET}"
echo "Ensuring PermitRootLogin is safe and keys are used."

# Allow targeting a specific host/group (default to 'all')
TARGET=${1:-all}

echo -e "${BLUE}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/.." || exit
ansible-playbook playbooks/configure-ssh.yml -i inventory/home-lab.ini --limit "$TARGET"

echo -e "${GREEN}[OK] Step 4 Complete. SSH is hardened.${RESET}"
