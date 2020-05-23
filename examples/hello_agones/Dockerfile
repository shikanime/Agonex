FROM hexpm/elixir:1.10.3-erlang-23.0.1-alpine-3.11.6@sha256:367c6ca84a3056f809af8057616737347c26cd633fedf9f969678ddadbd58dde AS source

ARG MIX_ENV=prod

WORKDIR /workspace

RUN apk update && apk add --no-cache git
RUN mix do local.hex --force, local.rebar --force

COPY mix.exs mix.lock ./
ENV MIX_ENV=${MIX_ENV}
RUN mix do deps.get --only ${MIX_ENV}, deps.compile, compile

COPY config config
RUN mix cmd --app cruise_web mix phx.digest

COPY . .
RUN mix release

FROM hexpm/erlang:23.0.1-alpine-3.11.6@sha256:23ec36050627fe3ec5b84dda8966c68629beac72a87b3086f4182b3b0efbd5ce

WORKDIR /hello_agones

COPY --from=source /workspace/_build/prod/rel/hello_agones .

ENV PATH=/hello_agones/bin:$PATH
EXPOSE 7654
CMD ["hello_agones", "start"]