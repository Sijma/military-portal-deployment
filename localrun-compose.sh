#!/bin/sh
set -eu

docker compose --env-file .env \
  -f docker-compose.yml \
  -f docker-compose.override.yml \
  up -d --build
