#! /bin/bash

echo 'Starting...'

bundle install
if [ "$?" != "0" ]; then
  echo 'Failed to perform bundle install!'
  exit 1
fi

bundle exec rake sunspot:solr:start

if [ "$?" != "0" ]; then
  echo 'Failed to start Solr!'
  exit 1
fi

# clean up any stale pids
rm /app/tmp/pids/server.pid &> /dev/null

rails s -b 0.0.0.0
if [ "$?" != "0" ]; then
  echo 'Failed to start Rails server!'
  exit 1
fi
