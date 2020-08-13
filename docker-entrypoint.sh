#!/bin/sh
set -eux

if [ "$1" = "ruby" ]; then
  if [ ! -z "$APP_UID" ] && [ ! -z "$APP_GID" ]; then
    usermod -u $APP_UID app
    groupmod -g $APP_GID app
  fi

  if [ "$(id -u)" = '0' ]; then
    find . \! -user app -exec chown app:app '{}' +
    exec gosu app "$@"
  fi
fi

exec "$@"
