FROM elixir:1.13.2  as build

# args
ARG MIX_ENV="prod"

# install runtime dependencies
RUN apt-get update -y 
    
RUN apt-get install -y build-essential \
    locales \
    gcc \
    erlang-dev \
    libvips \
    libvips-dev \ 
    libvips-tools

# install local Elixir hex and rebar
RUN mix local.hex --force \
 && mix local.rebar --force

#####################################################################################
# sets work dir
WORKDIR /app
COPY . /app

ENV MIX_ENV="prod"
ENV PORT=8080

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# install mix dependencies

RUN mix deps.get --only $MIX_ENV

# compile dependencies
RUN mix deps.compile

# compile project
RUN mix compile

# assemble release
RUN mix release

# app stage
FROM ubuntu:20.04 as app

ARG MIX_ENV

# install runtime dependencies
RUN apt-get update -y 

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
    
RUN apt-get install -y build-essential \
    libvips-dev

WORKDIR /app

# copy release executables
COPY --from=build  /app/_build/prod/rel/mahi /app

EXPOSE 8080

ENTRYPOINT ["/app/bin/mahi"]

CMD ["start"]
