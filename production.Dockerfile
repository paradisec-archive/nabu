FROM ruby:3.1.2-slim-bullseye AS assets

WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libmagic-dev \
    libmagickwand-dev \
    default-libmysqlclient-dev \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && useradd --create-home ruby \
  && mkdir /node_modules \
  && chown ruby:ruby -R /node_modules /app

USER ruby

COPY --chown=ruby:ruby Gemfile* ./
# RUN bundle config set --local deployment 'true'
# RUN bundle config set --local without 'development:test'
RUN bundle install --jobs "$(nproc)"

ARG RAILS_ENV="production"
ENV RAILS_ENV="${RAILS_ENV}" \
    PATH="${PATH}:/home/ruby/.local/bin" \
    USER="ruby"

COPY --chown=ruby:ruby . .

RUN bin/rails assets:clobber
RUN bin/rails assets:precompile

CMD ["bash"]

###############################################################################

FROM ruby:3.1.2-slim-bullseye AS app

WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libmagic-dev \
    libmagickwand-dev \
    default-libmysqlclient-dev \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && useradd --create-home ruby \
  && chown ruby:ruby -R /app

USER ruby

COPY --chown=ruby:ruby Gemfile* ./
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development:test'
RUN bundle install --jobs "$(nproc)"

COPY --chown=ruby:ruby bin/ ./bin
RUN chmod 0755 bin/*

ARG RAILS_ENV="production"
ENV RAILS_ENV="${RAILS_ENV}" \
    PATH="${PATH}:/home/ruby/.local/bin" \
    USER="ruby"

COPY --chown=ruby:ruby --from=assets /app/public /public
COPY --chown=ruby:ruby . .

COPY --chown=ruby:ruby vendor/assets ./vendor/

EXPOSE 8000

CMD ["bin/rails", "server", "--log-to-stdout"]
