#!/bin/bash
set -e

# Ensure all gems installed.
bundle check || bundle install

# Remove server.pid if it exists
if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

# Ensure migration is run & if no db create new
bundle exec rake db:migrate || bundle exec rake db:setup

# Finally call command issued to the docker service
exec "$@" 