#!/bin/bash
# status.sh
# Purpose: Check the Notebook Stack Status

TARGET=$1

cd "$(dirname "$0")/../.." || exit

if [ -n "$TARGET" ]; then
    ansible-playbook playbooks/notebook/status.yml -i inventory/home-lab.ini -e "manager_target=$TARGET"
else
    ansible-playbook playbooks/notebook/status.yml -i inventory/home-lab.ini
fi
