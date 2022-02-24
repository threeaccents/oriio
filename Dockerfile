FROM hexpm/elixir:1.13.3-erlang-24.0.2-ubuntu-bionic-20210325 as build

# args
ARG MIX_ENV="prod"

# set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


# install local Elixir hex and rebar
RUN mix local.hex --force \
 && mix local.rebar --force

#####################################################################################
# sets work dir
WORKDIR /app

ARG MIX_ENV
ENV MIX_ENV="${MIX_ENV}"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

# copy compile configuration files
RUN mkdir config
COPY config/config.exs config/$MIX_ENV.exs config/

# compile dependencies
RUN mix deps.compile

# copy assets
COPY priv priv
COPY assets assets

# Compile assets
RUN mix assets.deploy

# compile project
COPY apps apps
RUN mix compile

# copy runtime configuration file
COPY config/runtime.exs config/

# assemble release
RUN mix release

# app stage
FROM ubuntu:18.04 as app

ARG MIX_ENV

# install runtime dependencies
RUN apt-get update -q \
    libvips-dev

ENV USER="elixir"
ENV PORT=80

WORKDIR "/home/${USER}/app"

# Create  unprivileged user to run the release
RUN \
  addgroup \
   -g 1000 \
   -S "${USER}" \
  && adduser \
   -s /bin/sh \
   -u 1000 \
   -G "${USER}" \
   -h "/home/${USER}" \
   -D "${USER}" \
  && su "${USER}"

# run as user
USER "${USER}"

# copy release executables
COPY --from=build --chown="${USER}":"${USER}" /app/_build/"${MIX_ENV}"/rel/mahi ./  

ENTRYPOINT ["bin/mahi"]

CMD ["start"]