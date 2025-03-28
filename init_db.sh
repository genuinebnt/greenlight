#!/usr/bin/env bash
set -x
set -eo pipefail

if ! [ -x $(command -v psql) ]; then
  echo >&2 "Error: psql is not installed."
  exit 1
fi

DB_USER=${POSTGRES_USER:=postgres}
DB_PASSWORD=${POSTGRES_PASSWORD:=password}
DB_NAME=${POSTGRES_DB:=greenlight}
DB_PORT=${POSTGRES_PORT:=5432}

if [[ -z ${SKIP_DOCKER} ]]; then
  docker run \
    -e POSTGRES_USER=${DB_USER} \
    -e POSTGRES_PASSWORD=${DB_PASSWORD} \
    -e POSTGRES_DB=${DB_NAME} \
    -p ${DB_PORT}:5432 \
    -d postgres \
    postgres -N 1000
fi

export PGPASSWORD=${DB_PASSWORD}
until psql -h "localhost" -U ${DB_USER} -p ${DB_PORT} -d postgres -c '\q'; do
  echo >&2 "Postgres is still unavailable - sleeping"
  sleep 1
done

echo >&2 "Postgres is up and running on port ${DB_PORT}!"

GREENLIGHT_DB_DSN=postgres://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}?sslmode=disable
export GREENLIGHT_DB_DSN
