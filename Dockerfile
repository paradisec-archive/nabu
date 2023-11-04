# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.2
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"
# Unlike dhh we don;t think this image wil be used for CI

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential default-libmysqlclient-dev git libvips pkg-config

# App specific
RUN apt-get install --no-install-recommends -y \
      libcurl4-openssl-dev \
      libmagic-dev \
      libmagickwand-dev

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 PROXYIST_URL=dummy ./bin/rails assets:precompile


# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl default-mysql-client libvips && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install app packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libmagic1 libmagickwand-6.q16-6 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

RUN ln -nfs /dev/stdout log/delayed_job.log

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server", "--log-to-stdout"]

# RUN mkdir -p /home/johnf/work/nabu; ln -s /app /home/johnf/work/nabu/nabu

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
