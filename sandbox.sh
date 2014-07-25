#!/bin/sh -e

image_name=${ORIGINAL_SSH_COMMAND:-$USER}
docker pull "$image_name"
container_id=$(docker run -d "$image_name" /bin/sh -c "while true; do sleep 1; done")
PID=$(docker inspect --format {{.State.Pid}} $container_id)
if [ -z "$PID" ]; then
    exit 1
fi
shift
nsenter --target $PID --mount --uts --ipc --net --pid -- "$@"
docker commit -a "$USER" -m "Created by sandbox at $(date)" "$container_id" "$USER"
