#!/usr/bin/env bash

# A script to auto add ENV variables prior to docker-compose --build
source "$(git rev-parse --show-toplevel)/docker.env"
docker-compose "$@"

# ./compose.sh up --build # => docker-compose up --build
