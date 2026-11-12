# syntax = docker/dockerfile:1.7-labs
# check=error=true

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.9
FROM docker.io/library/node:lts-slim AS node

FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y curl default-mysql-client libjemalloc2 libvips && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install packages needed to build gems
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y build-essential default-libmysqlclient-dev libyaml-dev git pkg-config && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Node and pnpm; pnpm switches itself to the version in package.json's packageManager
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
  ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx && \
  npm install -g pnpm

# Set production environment
ENV RAILS_ENV="development" \
  BUNDLE_PATH="/usr/local/bundle"

# So rubocop works
RUN mkdir -p /home/johnf/work/nabu; ln -s /rails /home/johnf/work/nabu/nabu

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash
USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
# CMD ["./bin/thrust", "./bin/rails", "server"]
CMD ["./bin/dev"]
