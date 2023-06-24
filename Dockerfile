# ===============================================================
# Rails container for Nabu application
# - uses volumes for bundler and gem cache
# - uses entrypoint script to handle bundling and starting Solr
# ===============================================================

FROM ruby:3.1

ENV BUNDLE_PATH /bundler
ENV BUNDLE_HOME /gems

ENV GEM_HOME /gems
ENV GEM_PATH /gems

ENV PATH /gems/bin:$PATH


RUN apt-get update
RUN apt-get install -y \
  net-tools \
  ruby-kgio \
  git-core \
  curl \
  zlib1g-dev \
  build-essential \
  libssl-dev \
  libreadline-dev \
  libyaml-dev \
  libsqlite3-dev \
  sqlite3 \
  libxml2-dev \
  libxslt1-dev \
  libcurl4-openssl-dev \
  software-properties-common \
  libffi-dev \
  nodejs \
  libmagic-dev \
  openjdk-11-jre \
  wget \
  npm

RUN gem install bundler
RUN npm install --global yarn

# Chrome for headless testing
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt-get -y install ./google-chrome-stable_current_amd64.deb

VOLUME /app
WORKDIR /app

RUN mkdir -p /home/johnf/work/nabu; ln -s /app /home/johnf/work/nabu/nabu

CMD ["bin/rails", "server", "-b", "0.0.0.0"]
