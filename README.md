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
  -t ensc-mcl-dev-env .

docker run --rm -it \
  -v "$PWD:/workspace" \
  ensc-mcl-dev-env
```

For csh/tcsh:

```csh
docker build \
  --build-arg USERNAME=dev \
  --build-arg UID=`id -u` \
  --build-arg GID=`id -g` \
  -t ensc-mcl-dev-env .

docker run --rm -it \
  -v "$cwd:/workspace" \
  ensc-mcl-dev-env
```

Inside the container, verify the active user:

```sh
whoami
id
pwd
```
