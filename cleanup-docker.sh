#! /bin/sh

# Extracted from: https://www.github.com/matipuig/shell-utils
# Count how many word are in a string. 
# Use $(strings::count "Here the text")
strings::count(){
  echo "$@" | wc -w
}

#
# Start the cleanup.
#

echo "This shell command will delete all the images, containers and cache of docker. It won't erase the volumes. Do you wanna delete them? Press y/n"
read USER_INPUT
if [[ ${USER_INPUT} != "y" ]]; then
    exit 0
fi

# Erase all docker containers.
CONTAINERS_LIST=$(docker container ls -aq)
CONTAINERS_COUNT=$(strings::count ${CONTAINERS_LIST})
if [[ $CONTAINERS_COUNT != "0" ]]; then 
    echo "Cleaning containers: ''${CONTAINERS_LIST}''"
    docker container rm ${CONTAINERS_LIST}
else
    echo "No containers. Skipping..."
fi

# Erases all images.
IMAGES_LIST=$(docker images -q)
IMAGES_COUNT=$(strings::count ${IMAGES_LIST})
if [[ $IMAGES_COUNT != "0" ]]; then 
    echo "Cleaning images: ''${IMAGES_LIST}''"
    docker rmi ${IMAGES_LIST}
else 
    echo "No images. Skipping..."
fi

# Prune everything
echo "Pruning containers..."
docker container prune -f
echo "Pruning images..."
docker image prune -af
echo "Pruning builder..."
docker builder prune -af

echo ""
echo "Done! You should remember that if you are using docker-desktop, maybe you should use in the app the opcion purge Data in the debug options. But THIS WILL ALSO ERASE VOLUMES."
echo "Everything OK! Press any key to quit."
read USER_INPUT