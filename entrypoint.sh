#!/bin/bash
set -e

if [ -e tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

exec "$@"
