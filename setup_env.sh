#!/bin/bash
# setup_env.sh
# Purpose: Prepare the Control Node (your machine) with correct Ansible version and dependencies

set -e

GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

echo -e "${BLUE}[!] Preparing Control Node Environment...${RESET}"

# 1. Update system and install basic dependencies
echo -e "${YELLOW}[1/3] Installing system dependencies (sshpass)...${RESET}"
sudo apt update && sudo apt install -y sshpass python3-pip

# 2. Install/Upgrade Ansible Core
echo -e "${YELLOW}[2/3] Installing/Upgrading Ansible Core (>= 2.14)...${RESET}"
# We use pip to ensure a modern version compatible with Python 3.12 (Ubuntu 24.04 nodes)
python3 -m pip install --user --upgrade ansible-core

# 3. Configure PATH
echo -e "${YELLOW}[3/3] Checking PATH configuration...${RESET}"
LOCAL_BIN="$HOME/.local/bin"

if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    echo -e "${YELLOW}[!] Adding $LOCAL_BIN to PATH in .bashrc${RESET}"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
    echo -e "${GREEN}[✓] PATH updated. Please run 'source ~/.bashrc' after this script finishes.${RESET}"
else
    echo -e "${GREEN}[✓] $LOCAL_BIN is already in PATH.${RESET}"
fi

echo -e "\n${GREEN}[SUCCESS] Environment is ready!${RESET}"
echo -e "${BLUE}Current Ansible version:${RESET}"
ansible --version | head -n 1

echo -e "\n${YELLOW}[IMPORTANT] Please run the following command to refresh your current terminal session:${RESET}"
echo -e "${GREEN}source ~/.bashrc${RESET}\n"
