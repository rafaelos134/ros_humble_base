#!/bin/bash -e

# Re-map the in-container ${USERNAME} account to the host user that launched
# the container (LOCAL_UID/LOCAL_GID, exported by run_container.sh from
# `id -u`/`id -g`), so bind-mounted files under local_mount/ keep correct
# ownership no matter which host UID/GID runs the container — including on
# a shared/pre-built image, without needing a rebuild per user. Runs at
# every start (this entrypoint executes as root, see Dockerfile.entrypoint.common),
# and is a no-op whenever the host user already is uid/gid 1000 (the image
# default), which is also the common case.
TARGET_UID="${LOCAL_UID:-1000}"
TARGET_GID="${LOCAL_GID:-1000}"
CURRENT_UID="$(id -u "${USERNAME}")"
CURRENT_GID="$(id -g "${USERNAME}")"

if [ "${TARGET_UID}" != "${CURRENT_UID}" ]; then
    usermod -u "${TARGET_UID}" "${USERNAME}" \
        || echo "WARNING: could not set ${USERNAME}'s UID to ${TARGET_UID} (already taken?), keeping ${CURRENT_UID}"
fi
if [ "${TARGET_GID}" != "${CURRENT_GID}" ]; then
    groupmod -g "${TARGET_GID}" "${USERNAME}" \
        || echo "WARNING: could not set ${USERNAME}'s GID to ${TARGET_GID} (already taken?), keeping ${CURRENT_GID}"
fi
if [ "$(id -u "${USERNAME}")" != "${CURRENT_UID}" ] || [ "$(id -g "${USERNAME}")" != "${CURRENT_GID}" ]; then
    chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}"
fi

# Initialize the ROS workspace on every container start, so a plain
# `./run_container.sh` is enough to get a fully built workspace without
# needing to open this container through the VS Code Dev Containers
# extension. Dev Containers can still be used afterwards to attach to
# the already-running container.
mkdir -p "${ROS_WORKSPACE}/src"
chown -R "${USERNAME}:${USERNAME}" "${ROS_WORKSPACE}"

if [ -n "$(ls -A "${ROS_WORKSPACE}/src" 2>/dev/null)" ]; then
    gosu "${USERNAME}" bash -c "
        source /opt/ros/${ROS_DISTRO}/setup.bash
        cd '${ROS_WORKSPACE}'
        rosdep install --from-paths src --ignore-src --rosdistro '${ROS_DISTRO}' -y || true
        MAKEFLAGS=-j\$(nproc) colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release || true
    "
fi

exec "$@"
