FROM ghcr.io/language-research-technology/oni-ui:new-api

ARG ROCRATE_API_ENDPOINT
ARG ROCRATE_API_CLIENTID
ARG SENTRY_ENV

ENV BUMP=3

WORKDIR /

COPY oni.json /configuration.json
RUN sed -i "s#ROCRATE_API_ENDPOINT#$ROCRATE_API_ENDPOINT#;s#ROCRATE_API_CLIENTID#$ROCRATE_API_CLIENTID#;s#SENTRY_ENV#$SENTRY_ENV#" /configuration.json

WORKDIR /usr/share/nginx/html

COPY i18n i18n
COPY paradisec.jpg logo.jpg
