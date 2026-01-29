#!/bin/bash
# 01-bootstrap-connection.sh
# Purpose: Step 1 - Establish Initial Connection
# Usage: ./01-bootstrap-connection.sh

# Check for sshpass
if ! command -v sshpass &> /dev/null; then
    echo -e "${RED}[ERROR] sshpass is not installed. Please install it with: sudo apt install sshpass${RESET}"
    exit 1
fi

# Colors
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m" # Added RED color
RESET="\033[0m"

# Allow targeting a specific host/group (default to 'all')
TARGET=${1:-all}

echo -e "${YELLOW}[!] SETUP STEP 1: Bootstrapping SSH Connection${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}" # Moved this line here
echo "We will now deploy your SSH key to all servers defined in 'ansible/inventory/hosts'."
echo "You will be asked for the SSH Login Password for the servers."
echo -e "${YELLOW}Note: All servers should share the same password for this initial step.${RESET}"
echo ""

cd "$(dirname "$0")/.." || exit
ansible-playbook playbooks/init-ssh.yml -i inventory/init-home-lab.ini --limit "$TARGET" --ask-pass --ask-become-pass

echo -e "${GREEN}[OK] Step 1 Complete. You should now be able to run other scripts without a password.${RESET}"
