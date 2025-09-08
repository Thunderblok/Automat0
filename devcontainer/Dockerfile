FROM hexpm/elixir:1.17.2-erlang-27.0-debian-bookworm-20240612

# OS deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git curl wget ca-certificates libssl-dev \
    python3 python3-venv python3-pip pkg-config libzmq3-dev \
    rustc cargo \
    && rm -rf /var/lib/apt/lists/*

# Node for assets (LiveView) – optional
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

WORKDIR /workspaces/automat
COPY . .
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get || true

# Python venv for Cerebros
RUN python3 -m venv /opt/py && /opt/py/bin/pip install -U pip \
 && if [ -f python/requirements.txt ]; then /opt/py/bin/pip install -r python/requirements.txt; fi

ENV PYTHON_BIN=/opt/py/bin/python
ENV MIX_ENV=dev
CMD ["bash", "-lc", "iex -S mix run --no-halt"]
