FROM nvidia/cuda:13.0.1-cudnn-devel-ubuntu24.04
# FROM nvidia/cuda:13.0.1-cudnn-devel-ubuntu22.04

# Install necessary packages
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    less \
    wget \
    lsb-release \
    gpustat \
    git \
    curl \
    build-essential \
    tmux \
    htop \
    nano \
    vim \
    pipx \
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
    ninja-build

# Create /root/.ssh directory
RUN mkdir -p /root/.ssh

# Install openjdk 11
RUN curl -o /tmp/packages-microsoft-prod.deb https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb && \
    dpkg -i /tmp/packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    msopenjdk-11

# Install miniconda
ENV CONDA_DIR=/opt/conda
RUN curl -LsSf https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p /opt/conda

# Put conda in path so we can use conda activate
ENV PATH="${CONDA_DIR}/bin:${PATH}"

# Initialize conda
RUN conda init bash
RUN conda config --set auto_activate_base false

# Install uv, the fast Python package manager
RUN curl -LsSf https://astral.sh/uv/install.sh -o /tmp/uv-install.sh && \
  sh /tmp/uv-install.sh

# Add uv to the PATH
ENV PATH="/root/.local/bin:${PATH}"

# Install VSCode CLI
RUN curl -sL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" \
        --output /tmp/vscode-cli.tar.gz && \
    tar -xf /tmp/vscode-cli.tar.gz -C /usr/bin

# Enable color support for ls and grep in .bashrc
RUN echo 'if [ -x /usr/bin/dircolors ]; then\n    eval "$(dircolors -b)"\n    alias ls="ls --color=auto"\n    alias grep="grep --color=auto"\n    alias fgrep="fgrep --color=auto"\n    alias egrep="egrep --color=auto"\nfi' >> ~/.bashrc

# Add custom colored prompt to .bashrc
RUN echo 'PS1="\\[\\e[0;32m\\]\\u@\\h\\[\\e[m\\]:\\[\\e[0;34m\\]\\w\\[\\e[m\\]\\$ "' >> ~/.bashrc

# Enable colored output for less in .bashrc
RUN echo 'export LESS=" -R"' >> ~/.bashrc

# Enable color in the prompt for bash >= 4.0
RUN echo 'force_color_prompt=yes\nif [ -n "$force_color_prompt" ]; then\n    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then\n        color_prompt=yes\n    else\n        color_prompt=\n    fi\nfi\n\nif [ "$color_prompt" = yes ]; then\n    PS1="\\${debian_chroot:+(\$debian_chroot)}\\[\\033[01;32m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ "\nelse\n    PS1="\\${debian_chroot:+(\$debian_chroot)}\\u@\\h:\\w\\$ "\nfi\nunset color_prompt force_color_prompt' >> ~/.bashrc

RUN git config --global user.email "git@masoudka.com" && \
    git config --global user.name "Masoud KA"

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*
