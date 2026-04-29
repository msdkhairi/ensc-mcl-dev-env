# ENSC MCL Development Environment

This image runs as a non-root development user by default. The user name defaults
to `dev`, and the user and group IDs can be set at build time so files created in
bind-mounted project directories are owned by your host account.

Build this image on the host where you will run the development container. The
UID and GID are host-specific, so an image built in CI and pushed to Docker Hub
would only match the UID/GID from the CI builder, not necessarily your remote
development host.

## Build and Run

For sh/bash/zsh:

```sh
docker build \
  --build-arg USERNAME=dev \
  --build-arg UID=$(id -u) \
  --build-arg GID=$(id -g) \
  -t mcl-dev-env .

docker run -it \
  --name dev-remote \
  -v "$PWD:/home/dev/workspace" \
  --workdir /home/dev/workspace \
  mcl-dev-env

# Later sessions:
docker start -ai dev-remote
```

For csh/tcsh:

```csh
docker build \
  --build-arg USERNAME=dev \
  --build-arg UID=`id -u` \
  --build-arg GID=`id -g` \
  -t mcl-dev-env .

docker run -it \
  --name dev-remote \
  -v "$cwd:/home/dev/workspace" \
  --workdir /home/dev/workspace \
  mcl-dev-env

# Later sessions:
docker start -ai dev-remote
```

Inside the container, verify the active user:

```sh
whoami
id
pwd
```

Miniconda, `uv`, and the VS Code CLI are installed as the `dev` user under
`/home/dev/.local`, so the image does not need a slow recursive ownership change
over `/opt/conda`.

On the first interactive run of a new container, the entrypoint asks you to set
the `dev` user's sudo password. After that, normal commands run as `dev`, and
`sudo` prompts for the password you chose.

If you already have an older `dev-remote` container, rebuild the image and
recreate the container once so the new entrypoint and sudo behavior take effect:

```sh
REBUILD_IMAGE=1 RECREATE_CONTAINER=1 ./launch_code_tunnel_docker.sh
```

The launcher defaults to a container user named `dev`, with home directory
`/home/dev`. To build and run with a different container username, set
`CONTAINER_USERNAME` and rebuild the image. For example:

```sh
CONTAINER_USERNAME=mka267 REBUILD_IMAGE=1 RECREATE_CONTAINER=1 ./launch_code_tunnel_docker.sh
```

For csh/tcsh:

```csh
setenv CONTAINER_USERNAME mka267
setenv REBUILD_IMAGE 1
setenv RECREATE_CONTAINER 1
./launch_code_tunnel_docker.sh
```

That builds with `--build-arg USERNAME=mka267`, uses `/home/mka267/workspace`,
and defaults the container name to `mka267-remote`. You can still override paths
explicitly with `CONTAINER_HOME`, `CONTAINER_WORKSPACE_DIR`,
`CONTAINER_CONDA_DIR`, or `CONTAINER_DATASETS_DIR`.
