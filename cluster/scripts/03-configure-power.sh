#!/bin/bash
# 03-configure-power.sh
# Purpose: Step 3 - Configure Power Management (Lid Close)
# Usage: ./03-configure-power.sh

GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}[!] SETUP STEP 3: Configuring Power Management${RESET}"
echo "Disabling sleep on lid close and turning off Wi-Fi power save..."

# Allow targeting a specific host/group (default to 'all')
TARGET=${1:-all}

echo -e "${BLUE}[!] Target: $TARGET${RESET}"

cd "$(dirname "$0")/.." || exit
ansible-playbook playbooks/configure-power.yml -i inventory/home-lab.ini --limit "$TARGET"

echo -e "${GREEN}[OK] Step 3 Complete. Laptop nodes will now stay awake.${RESET}"
