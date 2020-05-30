# syntax = docker/dockerfile:experimental

FROM hexpm/elixir:1.10.3-erlang-23.0.1-alpine-3.11.6 AS builder

WORKDIR /agonex/src/examples/hello_agones/

RUN --mount=type=cache,id=apk,sharing=locked,target=/var/cache/apk \
  apk add --update git
RUN mix do local.hex --force, local.rebar --force

COPY mix.* /agonex/src/
COPY examples/hello_agones/mix.* ./

RUN --mount=id=hex-cache,type=cache,sharing=locked,target=/root/.hex \
  --mount=id=deps-cache,type=cache,sharing=locked,target=./deps \
  mix do deps.get

COPY lib /agonex/src/lib
COPY examples/hello_agones/lib ./lib
COPY examples/hello_agones/config ./config
COPY examples/hello_agones/rel ./rel

FROM builder AS releaser

RUN --mount=id=deps-cache,type=cache,sharing=locked,target=./deps \
  mix release --overwrite

FROM alpine:3.11.6 AS runner

RUN --mount=type=cache,id=apk,sharing=locked,target=/var/cache/apk \
  ln -vs /var/cache/apk /etc/apk/cache && \
  apk add --update openssl ncurses

ENV RELEASE_TMP=/tmp

COPY --from=releaser /agonex/src/examples/hello_agones/_build/dev/rel/hello_agones /hello_agones

ENV PATH=/hello_agones/bin:$PATH

EXPOSE 7654

ENTRYPOINT [ "hello_agones" ]
CMD ["start"]
