if [ "$1" == "push" ]; then

    if [ -f .env ]; then
        sops -e .env > enc.env
    fi

    git add -A
    git commit -a -m "$2"
    git push
elif [ "$1" == "pull" ]; then
    git pull

    if [ -n "$(git diff HEAD~1 HEAD --name-only | grep 'enc.env')" ]; then
        echo "Encrypted .env file has changed, decrypting..."
        sops -d enc.env > .env
        if [ "$(hostname)" == "sargas" ]; then
            echo "Restarting Docker Compose services..."
            docker-compose down
            docker-compose up -d
        fi
    else
        echo "No changes in encrypted .env file, no action taken."
    fi
fi