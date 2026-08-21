# ros2_humble_docker_vnc_dev
The sources of the base ROS2 Humble Docker image for development with devcontainers. This image has a lot of things installed, including VNC and Code server, and makes easy to develop locally or on the robot.

<details>
<summary> Details of the services in this container </summary>

- ROS2 humble with a base workspace `/home/ubuntu/ros2_ws/`;
- Support for arm64 (jetson orin nano) and amd64 architectures;
- Support for NVIDIA Docker runtime for linux hosts;
- VNC server that allows direct browser access (http://localhost:3080/), so nothing is required to install and use it;
- A `ssh` server, to allow direct access from outside (`ssh ubuntu@localhost -p 3022`);
- A web `vscode` server for easy remote access when deploying it on the robot (http://localhost:3081/);
- Automatic `xcode +` command executed on each attachment for local X forwarding;
- Custom environment and VScode configurations:
  - Open split terminals on launch;
  - Setup all environments variables automatically for running ROS;
  - Automatically open the VNC interface in a ROS tab;
  - Custom PS1 (terminal shell);
</details>

### Build and start the container

The container is built and started with `run_container.sh` — this is the supported way to
create/start it; no VS Code or Dev Containers extension is required:

- `git clone git@github.com:h3ct0r/ros2_humble_docker_vnc_dev.git`
- `cd ros2_humble_docker_vnc_dev`
- `./run_container.sh linux` (or `nvidia` / `rasp` / `rootless`, see `./run_container.sh --help`)

On every start, the entrypoint automatically runs `rosdep install` and `colcon build` for whatever
is mounted under `local_mount/src`, so the workspace is ready without any extra setup step.

#### File ownership, for any host user

`run_container.sh` exports `LOCAL_UID`/`LOCAL_GID` from `id -u`/`id -g` of whoever runs it, and
every compose file passes them through as environment variables. At every container start,
`docker/entrypoint.sh` (running as root) `usermod`/`groupmod`s the in-container `ubuntu` account
to match them, then `chown -R`s its home directory, before dropping to `ubuntu` (via `gosu`) to
build the workspace. This is a runtime fixup, not a build argument, so:

- It works for any host UID/GID — 1000 or otherwise — without any code change.
- It's a no-op (nothing to change) when the host user already is uid/gid 1000, the image default.
- The same pre-built/pushed image (see "Build and Push" below) works correctly for every user on
  a shared machine, since the fix happens at container start, not at image build time — baking
  the UID in as a build arg instead would force a full image rebuild for every different user.

<details>
  <summary>Equivalent manual docker compose invocation</summary>

- `BUILDKIT_PROGRESS=plain docker compose -f compose_linux.yaml up --build`

`BUILDKIT_PROGRESS=plain` helps to visualize step by step output of each of the commands.
</details>

### Running under rootless Docker

`compose_linux_rootless.yaml` (used by `./run_container.sh rootless`) is a variant tuned to
start cleanly under a [rootless Docker daemon](https://docs.docker.com/engine/security/rootless/):

- `network_mode: host` is replaced with `bridge` + explicit `ports:` for VNC (`3080`, `5902`),
  code-server (`3081`) and ssh (`3022`). Rootless Docker does **not** support the `host` network
  driver — a host-network container only joins RootlessKit's own isolated netns, so its ports
  are not reachable from the real host or LAN at all, which is why plain `compose_linux.yaml`
  won't expose a usable VNC session under rootless.
- `privileged: true`, `device_cgroup_rules` and the `/dev:/dev` bind mount are dropped. None of
  them are needed to run VNC/code-server/ssh, and a rootless dockerd generally can't grant the
  cgroup device-controller delegation or host device access they rely on — keeping them tends to
  make the container fail to start rather than just lose functionality.
- `cap_add` is trimmed to `SYS_PTRACE` (useful for `gdb`); `NET_ADMIN`/`SYS_MODULE` are removed
  since a rootless daemon can't grant capabilities that require real host privileges.
- NVIDIA GPUs are still exposed via `runtime: nvidia` + a `deploy.resources.reservations`
  device request (same as `compose_linux_nvidia.yaml`). This requires the rootless daemon's own
  `daemon.json` to have been set up with `nvidia-ctk runtime configure --runtime=docker
  --config=<rootless daemon.json>` first — the `docker-rootless-create-dir` helper used on the
  VeRLab/JLab network already does this — so the `nvidia` runtime is registered for that user's
  rootless daemon.

To use it with a rootless Docker daemon (e.g. the `docker-rootless-export` style helpers used on
the VeRLab/JLab network), export `DOCKER_HOST` to point at the rootless daemon's socket first,
then run as usual:

- `docker-rootless-export` (or manually `export DOCKER_HOST=unix://$USER_DOCKER_DIR/.docker/run/docker.sock`)
- `./run_container.sh rootless`

Known limitation: the UID/GID remap described above (see "File ownership, for any host user")
still runs and makes the in-container `ubuntu` account match your real UID/GID numerically — but
rootless Docker itself maps every non-zero container UID to a subordinate UID range on the host
(this is structural to how rootless Docker works, not something a compose file can turn off), so
files created inside the container under `./local_mount` will still show up on the host owned by
a high subuid rather than your own user, even though they're fully accessible from inside the
container.

### Connecting with VS Code Dev Containers

Once the container is up (via `run_container.sh`), attach VS Code to it with the Dev Containers
extension's **"Attach to Running Container"** command and pick `ros2_humble_development`. Dev
Containers is only used here to connect an editor to the already-running container — it is not
used to build or start it.

### Build and Push

- `BUILDKIT_PROGRESS=plain docker compose -f compose_macos.yaml build`
- `docker image push h3ct0rdcc/ros2_humble_development:amd64`
- `docker image push h3ct0rdcc/ros2_humble_development:latest`

### Access to services

Once the container is up, the you can access the services via:

- VNC: http://localhost:3080
- VScode: http://localhost:3081
- SSH: `ssh ubuntu@localhost -p 3022`
  - user: `ubuntu`
  - pass: `ubuntu`
 
