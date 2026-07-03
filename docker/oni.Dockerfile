FROM ghcr.io/crate-works/oni:1.3.0

ARG ROCRATE_API_ENDPOINT
ARG ROCRATE_API_CLIENTID
ARG SENTRY_ENV

ENV BUMP=12

WORKDIR /

COPY oni.json /configuration.json
RUN sed -i "s#ROCRATE_API_ENDPOINT#$ROCRATE_API_ENDPOINT#;s#ROCRATE_API_CLIENTID#$ROCRATE_API_CLIENTID#;s#SENTRY_ENV#$SENTRY_ENV#" /configuration.json

WORKDIR /usr/share/nginx/html

COPY i18n i18n
COPY paradisec.jpg logo.jpg
COPY redirects.conf /etc/nginx/oni.d/01-redirects.conf
