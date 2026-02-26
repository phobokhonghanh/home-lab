#!/bin/bash
# deploy.sh
# Purpose: Deploy the Notebook Stack

TARGET=$1

cd "$(dirname "$0")/../.." || exit

if [ -n "$TARGET" ]; then
    ansible-playbook playbooks/notebook/deploy.yml -i inventory/home-lab.ini -e "manager_target=$TARGET"
else
    ansible-playbook playbooks/notebook/deploy.yml -i inventory/home-lab.ini
fi
