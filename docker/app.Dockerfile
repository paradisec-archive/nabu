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

###############################################################################
#
FROM builder as bundler
WORKDIR /tmp
RUN gem install bundler
COPY Gemfile Gemfile.lock /tmp
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development:test'
RUN bundle install --jobs "$(nproc)"

FROM node as yarn
COPY cron-worker /tmp/cron-worker
WORKDIR /tmp/cron-worker
RUN npm install && \
  npm run build

RUN ls /tmp
RUN ls /tmp/cron-worker

FROM builder as assets
WORKDIR /tmp
COPY --from=bundler /usr/local/bundle /usr/local/bundle
COPY --from=bundler /tmp/vendor/bundle /tmp/vendor/bundle
COPY app app
COPY bin bin
COPY config config
COPY lib lib
COPY vendor/assets vendor/assets
COPY Rakefile Gemfile Gemfile.lock .

RUN PROXYIST_URL=dummy RAILS_ENV=production bundle exec rails assets:precompile

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

# Node bits
RUN apt-get update -qq && \
  apt-get install -y ca-certificates curl gnupg && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg && \
  apt-key add /usr/share/keyrings/nodesource.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
  apt-get update && \
  apt-get install nodejs -y && \
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

COPY --from=yarn /tmp/cron-worker/node_modules cron-worker/node_modules
COPY --from=yarn /tmp/cron-worker/index.js cron-worker/index.js

RUN mkdir log
RUN ln -s /dev/stdout log/delayed_job.log

ENV \
  RAILS_ENV="production"
  # USER="ruby"
 # PATH="${PATH}:/home/ruby/.local/bin" \


CMD ["bin/rails", "server", "--log-to-stdout", "--port", "3000"]
