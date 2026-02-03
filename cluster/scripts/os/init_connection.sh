#!/bin/bash
# init_connection.sh
# Purpose: Step 1 - Establish Initial Connection

# Check for sshpass
if ! command -v sshpass &> /dev/null; then
    echo -e "\033[31m[ERROR] sshpass is not installed. Please install it with: sudo apt install sshpass\033[0m"
    exit 1
fi

# Colors
YELLOW="\033[33m"
RESET="\033[0m"

# Allow targeting a specific host/group (default to 'all')
TARGET=${1:-all}

echo -e "${YELLOW}[!] SETUP STEP 1: Bootstrapping SSH Connection${RESET}"
echo -e "${YELLOW}[!] Target: $TARGET${RESET}"
echo "We will now deploy your SSH key to all servers."

cd "$(dirname "$0")/../.." || exit
ansible-playbook playbooks/os/bootstrap.yml -i inventory/init-home-lab.ini --limit "$TARGET" --ask-pass --ask-become-pass
