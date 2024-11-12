# syntax=docker/dockerfile:1.7-labs
## NOTE: Above so we can use exclude
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t nabu .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name nabu nabu

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Accept the GIT_SHA build argument
ARG GIT_SHA

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
        apt-get install --no-install-recommends -y curl default-mysql-client libjemalloc2 libvips && \
        rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
        BUNDLE_DEPLOYMENT="1" \
        BUNDLE_PATH="/usr/local/bundle" \
        BUNDLE_WITHOUT="development:test"
# Unlike dhh we don;t think this image wil be used for CI

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
        apt-get install --no-install-recommends -y build-essential default-libmysqlclient-dev git pkg-config && \
        rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV NODE_VERSION=22.11.0
ENV NVM_DIR /usr/local/nvm
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

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
        rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
        bundle exec bootsnap precompile --gemfile

# Install node modules
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

# Sentry setup
RUN echo $GIT_SHA > REVISION

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN ASSET_PRECOMPILE=1 SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

RUN rm -rf node_modules



# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build --exclude=tmp/cache/* --exclude=vendor/bundle /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
        useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
        chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server", "--log-to-stdout", "-b", "0.0.0.0"]
