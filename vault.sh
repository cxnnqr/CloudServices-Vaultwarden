#!/usr/bin/env bash

if [ ! -f "./ansible.cfg" ]; then
    echo "Run at the root of the git repo!"
    exit 1
fi

if [ ! -f ./"group_vars/all/secrets.yml" ]; then
    echo "${ANSIBLE_VAULT_PASSWORD}" > /tmp/.vault_pass
fi
