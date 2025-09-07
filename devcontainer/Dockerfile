FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && apt-get install -y --no-install-recommends \
    locales git curl wget unzip build-essential python3-venv python3-pip \
    inotify-tools && \
    rm -rf /var/lib/apt/lists/*

# Erlang + Elixir via asdf (preinstalled in this base variant typically) could be wired here

WORKDIR /workspaces/automat
CMD ["sleep", "infinity"]
