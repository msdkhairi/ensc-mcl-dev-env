FROM debian:12.13-slim

# Install system packages as root.
ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    sudo \
    openssh-client \
    unzip \
    less \
    wget \
    lsb-release \
    git \
    curl \
    build-essential \
    tmux \
    htop \
    nano \
    vim \
    libreadline-dev \
    libncursesw5-dev \
    libssl-dev \
    libsqlite3-dev \
    libgdbm-dev \
    libc6-dev \
    libbz2-dev \
    libffi-dev \
    libpq-dev \
    liblzma-dev \
    libopenblas-dev \
    libgl1-mesa-dev \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    ffmpeg \
    tk-dev \
    direnv \
    ninja-build

# Create /root/.ssh directory
RUN mkdir -p /root/.ssh

# Install openjdk 11
RUN curl -o /tmp/packages-microsoft-prod.deb https://packages.microsoft.com/config/debian/$(lsb_release -rs)/packages-microsoft-prod.deb && \
    dpkg -i /tmp/packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    msopenjdk-11

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# Create the non-root development user before installing user-managed tools.
RUN set -eux; \
    if ! getent group "${GID}" >/dev/null; then \
        groupadd --gid "${GID}" "${USERNAME}"; \
    fi; \
    useradd --no-log-init --uid "${UID}" --gid "${GID}" --create-home --shell /bin/bash "${USERNAME}"; \
    install -d -m 700 -o "${UID}" -g "${GID}" "/home/${USERNAME}/.ssh"; \
    install -d -m 755 -o "${UID}" -g "${GID}" \
        "/home/${USERNAME}/.local" \
        "/home/${USERNAME}/.local/bin" \
        "/home/${USERNAME}/workspace"; \
    mkdir -p \
        /usr/local/bin \
        /usr/local/sbin \
        /var/lib/devcontainer; \
    printf '%s\n' \
        "${USERNAME} ALL=(ALL) ALL" \
        "${USERNAME} ALL=(root) NOPASSWD: /usr/local/sbin/set-dev-sudo-password" \
        > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY set-dev-sudo-password /usr/local/sbin/set-dev-sudo-password
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh /usr/local/sbin/set-dev-sudo-password

ENV HOME=/home/${USERNAME}
ENV USER=${USERNAME}
ENV DEV_USERNAME=${USERNAME}
ENV CONDA_DIR=/home/${USERNAME}/.local/conda
ENV UV_INSTALL_DIR=/home/${USERNAME}/.local/bin
ENV PATH="${HOME}/.local/bin:${CONDA_DIR}/bin:/usr/local/bin:${PATH}"
RUN echo 'export PATH="$HOME/.local/bin:${CONDA_DIR}/bin:/usr/local/bin:$PATH"' > /etc/profile.d/dev-path.sh

USER ${USERNAME}
WORKDIR /home/${USERNAME}/workspace

# Install user-managed development tools as the dev user.
RUN curl -LsSf https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p "${CONDA_DIR}" && \
    rm /tmp/miniconda.sh
RUN conda config --set auto_activate_base false

RUN curl -LsSf https://astral.sh/uv/install.sh -o /tmp/uv-install.sh && \
    sh /tmp/uv-install.sh && \
    rm /tmp/uv-install.sh

RUN curl -sL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" \
        --output /tmp/vscode-cli.tar.gz && \
    tar -xf /tmp/vscode-cli.tar.gz -C "${HOME}/.local/bin" && \
    rm /tmp/vscode-cli.tar.gz

# Enable color support for ls and grep in .bashrc
RUN echo 'if [ -x /usr/bin/dircolors ]; then\n    eval "$(dircolors -b)"\n    alias ls="ls --color=auto"\n    alias grep="grep --color=auto"\n    alias fgrep="fgrep --color=auto"\n    alias egrep="egrep --color=auto"\nfi' >> "${HOME}/.bashrc"

# Add custom colored prompt to .bashrc
RUN echo 'PS1="\\[\\e[0;32m\\]\\u@\\h\\[\\e[m\\]:\\[\\e[0;34m\\]\\w\\[\\e[m\\]\\$ "' >> "${HOME}/.bashrc"

# Enable colored output for less in .bashrc
RUN echo 'export LESS=" -R"' >> "${HOME}/.bashrc"

# Enable color in the prompt for bash >= 4.0
RUN echo 'force_color_prompt=yes\nif [ -n "$force_color_prompt" ]; then\n    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then\n        color_prompt=yes\n    else\n        color_prompt=\n    fi\nfi\n\nif [ "$color_prompt" = yes ]; then\n    PS1="\\${debian_chroot:+(\$debian_chroot)}\\[\\033[01;32m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ "\nelse\n    PS1="\\${debian_chroot:+(\$debian_chroot)}\\u@\\h:\\w\\$ "\nfi\nunset color_prompt force_color_prompt' >> "${HOME}/.bashrc"

RUN git config --global user.email "git@masoudka.com" && \
    git config --global user.name "Masoud KA"

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
