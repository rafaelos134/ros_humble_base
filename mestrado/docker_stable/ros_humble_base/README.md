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

### Dev Containers

For a complete tutorial on how to use this repo using devcontainers VScode check: 
- https://github.com/h3ct0r/ros2_devcontainer_docker_compose

### Headless run with `docker compose`

<details>
  <summary>Recommended for remote development, as for example, deploying a dev machine on the robot.</summary>
  
- `git clone git@github.com:h3ct0r/ros2_humble_docker_vnc_dev.git`
- `cd ros2_humble_docker_vnc_dev`
- `BUILDKIT_PROGRESS=plain docker compose -f compose_linux.yaml up --build`

`BUILDKIT_PROGRESS=plain` helps to visualize step by step output of each of the commands.
</details>

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
 
