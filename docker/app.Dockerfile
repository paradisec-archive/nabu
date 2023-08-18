ARG RUBY_VERSION=3.1.3

###############################################################################
#
FROM ruby:$RUBY_VERSION-slim-bullseye AS builder
WORKDIR /tmp
RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libmagic-dev \
    libmagickwand-dev \
    libcurl4-openssl-dev \
    default-libmysqlclient-dev

  # libssl-dev \
  # libreadline-dev \
  # libyaml-dev \
  # libsqlite3-dev \
  # sqlite3 \
  # libxml2-dev \
  # libxslt1-dev \
  # libcurl4-openssl-dev \

###############################################################################
#
FROM builder as bundler
WORKDIR /tmp
RUN gem install bundler
COPY Gemfile Gemfile.lock /tmp
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development:test'
RUN bundle install --jobs "$(nproc)"
RUN ls /tmp/vendor/bundle
RUN ls /usr/local/bundle

# FROM node as yarn
# WORKDIR /tmp
# COPY package.json yarn.lock /
# RUN yarn install

FROM builder as assets
WORKDIR /tmp
COPY --from=bundler /usr/local/bundle /usr/local/bundle
COPY --from=bundler /tmp/vendor/bundle /tmp/vendor/bundle
# COPY --from=yarn /tmp/node_modules node_modules
COPY app app
COPY bin bin
COPY config config
COPY lib lib
COPY vendor/assets vendor/assets
COPY Rakefile Gemfile Gemfile.lock .

RUN RAILS_ENV=production bundle exec rails assets:precompile

###############################################################################
#
FROM ruby:$RUBY_VERSION-slim-bullseye AS app

RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
    libmagic1 \
    libmagickwand-6.q16-6 \
    libcurl4 \
    libmariadb3 && \
  apt-get clean && \
  rm  -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

WORKDIR /app

RUN useradd --create-home ruby

RUN chown ruby:ruby /app

COPY --from=bundler /usr/local/bundle /usr/local/bundle


USER ruby

COPY --chown=ruby:ruby --from=bundler /tmp/vendor/bundle vendor/bundle
COPY --chown=ruby:ruby --from=assets /tmp/public/assets public/assets

COPY --chown=ruby:ruby . .

ENV \
  RAILS_ENV="production"
  # USER="ruby"
 # PATH="${PATH}:/home/ruby/.local/bin" \


CMD ["bin/rails", "server", "--log-to-stdout", "--port", "3000"]
