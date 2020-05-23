#!/usr/bin/env sh

set -o errexit
set -o nounset

protoc \
  -I ./proto \
  -I $GOPATH/src/github.com/googleapis/googleapis \
  --elixir_out=plugins=grpc:./lib ./proto/agones/dev/sdk/sdk.proto \
  $GOPATH/src/github.com/googleapis/googleapis/google/api/annotations.proto \
  $GOPATH/src/github.com/googleapis/googleapis/google/api/http.proto