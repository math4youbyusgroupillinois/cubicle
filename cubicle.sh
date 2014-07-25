#!/bin/sh -ex
array_contains() {
    local array="$1[@]"
    local seeking=$2
    local in=1
    for element in "${!array}"; do
        if [[ $element == $seeking ]]; then
            in=0
            break
        fi
    done
    return $in
}

image_name=${ORIGINAL_SSH_COMMAND:-$USER}
installed_images=($(docker images | awk '{ print $1 }'))
if ! array_contains installed_images "$image_name"; then
    docker pull "$image_name"
fi

container_id=$(docker run -d -v $HOME:$HOME --name=$USER "$image_name"  /bin/sh -c "while true; do sleep 1; done")

PID=$(docker inspect --format {{.State.Pid}} $container_id)
if [ -z "$PID" ]; then
    exit 1
fi

uid=$(id -u $USER)

echo "Adding user $USER."
echo "Entering container $container_id."
set +e
sudo nsenter --target $PID --mount --uts --ipc --net --pid -- /usr/sbin/useradd $USER --uid $uid --no-create-home -s $SHELL
set -e
sudo nsenter --target $PID --mount --uts --ipc --net --pid -- /bin/login -f $USER

echo "Committing container $container_id."
docker stop $container_id &> /dev/null
new_image=$(docker commit -a "$USER" -m "Created by sandbox at $(date)" "$container_id" "$USER") &> /dev/null
echo "Container saved as image $new_image."
docker rm $container_id  &> /dev/null
