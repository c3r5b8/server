#!/bin/bash

function encrypt_env_file() {
    if [ -f .env ]; then
        sops -e .env > enc.env
    fi
}

function commit_and_push() {
    git add -A
    git commit -a -m "$1"
    git push
}

function decrypt_env_file() {
    if [ -n "$(git diff HEAD~1 HEAD --name-only | grep 'enc.env')" ]; then
        echo "Encrypted .env file has changed, decrypting..."
        sops -d enc.env > .env
        if [ "$(hostname)" == "vm-debian" ]; then
            echo "Restarting Docker Compose services..."
            sudo docker compose down
            sudo docker compose up -d --remove-orphans
        fi
    else
        echo "No changes in encrypted .env file, no action taken."
        sudo docker compose up -d --remove-orphans
    fi
}

function push_changes() {
    if [ -z "$2" ]; then
        echo "Error: Please provide a commit message."
        exit 1
    fi

    env_file=$(cat .env)
    enc_env_file=$(sops -d enc.env)
    diff_output=$(diff <(echo "$env_file") <(echo "$enc_env_file"))
    if [ -n "$diff_output" ]; then
        echo "Changes in .env file detected, encrypting..."
        encrypt_env_file
    else
        echo "No changes in .env file, no action taken."
    fi    
    commit_and_push "$2"
}

function pull_changes() {
    git pull
    decrypt_env_file
}

if [ "$1" == "push" ]; then
    push_changes "$1" "$2"
elif [ "$1" == "pull" ]; then
    pull_changes
fi
