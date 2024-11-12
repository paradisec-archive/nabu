# syntax = docker/dockerfile:1.7-labs
# check=error=true

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
        apt-get install --no-install-recommends -y curl default-mysql-client libjemalloc2 libvips && \
        rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install packages needed to build gems
RUN apt-get update -qq && \
        apt-get install --no-install-recommends -y build-essential default-libmysqlclient-dev git pkg-config && \
        rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV NODE_VERSION=22.11.0
ENV NVM_DIR /usr/local/nvm
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT 0
RUN mkdir -p $NVM_DIR
# Setup node
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash && \
        . $NVM_DIR/nvm.sh && \
        nvm install $NODE_VERSION && \
        nvm alias default $NODE_VERSION  && \
        nvm use default && \
        corepack enable

ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

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
