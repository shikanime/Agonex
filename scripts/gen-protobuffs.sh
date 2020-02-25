#!/usr/bin/env sh

set -o errexit
set -o nounset

protoc -I $GOPATH/src/github.com/googleapis/googleapis -I ./protos --elixir_out=plugins=grpc:./lib ./protos/agonex/sdk.proto
protoc -I $GOPATH/src/github.com/googleapis/googleapis -I ./protos --elixir_out=plugins=grpc:./lib ./protos/agonex/sdk.proto $GOPATH/src/github.com/googleapis/googleapis/google/api/annotations.proto $GOPATH/src/github.com/googleapis/googleapis/google/api/http.proto