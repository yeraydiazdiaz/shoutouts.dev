FROM ubuntu:20.04

ENV REFRESHED_AT=2020-09-26 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    HOME=/opt/build \
    TERM=xterm \
    DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    COOKIE=${COOKIE} \
    APPSIGNAL_PUSH_API_KEY=${APPSIGNAL_PUSH_API_KEY}

WORKDIR /opt/build

# Split into to layers because locale-gen failed otherwise
RUN \
    apt-get update -y && \
    apt-get install -y git wget vim locales gnupg

# TODO: installing erlang & elixir installs a _lot_ of stuff including xserver
# the JVM and Python. We're not deploying this image so I guess it's fine?
RUN \
    locale-gen en_US.UTF-8 && \
    wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && \
    dpkg -i erlang-solutions_2.0_all.deb && \
    rm erlang-solutions_2.0_all.deb && \
    apt-get update -y && \
    apt-get install -y erlang elixir build-essential ca-certificates curl

# Install nodejs 14, 20.04 is at 10
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs

# Install updated versions of hex/rebar
RUN mix local.rebar --force
RUN mix local.hex --if-missing --force

ENV MIX_ENV prod

# Copy dependency files and install them
COPY mix.exs mix.lock /opt/build/
COPY config /opt/build/config/
COPY apps/shoutouts/mix.exs /opt/build/apps/shoutouts/
COPY apps/shoutouts_web/mix.exs /opt/build/apps/shoutouts_web/

RUN mix deps.get
RUN mix do clean, compile --force

# Copy the JS dependency files and install them
COPY apps/shoutouts_web/assets/package.json apps/shoutouts_web/assets/package-lock.json /opt/build/apps/shoutouts_web/assets/
WORKDIR /opt/build/apps/shoutouts_web/assets/
RUN npm install -g npm
RUN npm install
WORKDIR /opt/build

# Copy all the app files
COPY . /opt/build/

CMD ["/bin/bash"]
