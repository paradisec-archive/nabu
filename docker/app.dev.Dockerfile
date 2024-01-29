# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.2
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="development" \
  BUNDLE_PATH="/usr/local/bundle"

# Install packages needed to build gems
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y build-essential default-libmysqlclient-dev git libvips pkg-config

# App specific
RUN apt-get install --no-install-recommends -y \
  libcurl4-openssl-dev \
  libmagic-dev \
  libmagickwand-dev

# So rubocop works
RUN mkdir -p /home/johnf/work/nabu; ln -s /rails /home/johnf/work/nabu/nabu

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash
USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]


# RUN cd /tmp \
# && curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
# && unzip -q awscliv2.zip \
# && ./aws/install \
# && rm -rf /tmp/awscliv2.zip /tmp/aws \
# && curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" \
# && dpkg -i session-manager-plugin.deb
# Stuff we might need
# net-tools \
# ruby-kgio \
# git-core \
# curl \
# zlib1g-dev \
# build-essential \
# libssl-dev \
# libreadline-dev \
# libsqlite3-dev \
# sqlite3 \
# libxml2-dev \
# libxslt1-dev \
# software-properties-common \
# libffi-dev \
# nodejs \
# openjdk-17-jre \
# wget \
# npm


# Chrome for headless testing
# RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# RUN apt-get -y install ./google-chrome-stable_current_amd64.deb

