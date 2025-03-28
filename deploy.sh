#!/usr/bin/env bash

REPO=$HOME/CloudServices-Vaultwarden

# Enter repo
cd "$REPO" || exit 1

# Copy inventory file
cp /etc/ansible/hosts inventory

# Exec playbook-init
if [ ! -f "$REPO/group_vars/all/secrets.yml" ]; then
    ansible-playbook playbook-init.yml
fi

# Exec playbook-deploy
ansible-playbook playbook-deploy.yml --ask-vault-pass --ask-become
