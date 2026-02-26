#!/bin/bash
# remove.sh
# Purpose: Remove the Notebook Stack

TARGET=$1

cd "$(dirname "$0")/../.." || exit

if [ -n "$TARGET" ]; then
    ansible-playbook playbooks/notebook/remove.yml -i inventory/home-lab.ini -e "manager_target=$TARGET"
else
    ansible-playbook playbooks/notebook/remove.yml -i inventory/home-lab.ini
fi
