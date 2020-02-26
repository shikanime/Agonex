FROM hexpm/elixir:1.10.3-erlang-23.0.1-alpine-3.11.6@sha256:367c6ca84a3056f809af8057616737347c26cd633fedf9f969678ddadbd58dde
WORKDIR /agonex

COPY mix.* .
RUN mix do deps.get, deps.compile

COPY . .
RUN mix compile
