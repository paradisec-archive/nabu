###############################################################################
#
FROM node:lts AS builder

ARG ROCRATE_API_ENDPOINT
ARG ROCRATE_API_CLIENTID
ARG SENTRY_ENV

ENV VITE_ONI_CONFIG_PATH=/oni/configuration.json

RUN corepack enable

RUN touch bump-8

WORKDIR /tmp

RUN git clone https://github.com/Language-Research-Technology/oni-ui.git -b new-api

WORKDIR /tmp/oni-ui

COPY docker/oni.json public/configuration.json
COPY docker/i18n public/i18n
COPY app/assets/images/paradisec.jpg public/logo.jpg

RUN sed -i "s#ROCRATE_API_ENDPOINT#$ROCRATE_API_ENDPOINT#;s#ROCRATE_API_CLIENTID#$ROCRATE_API_CLIENTID#;s#SENTRY_ENV#$SENTRY_ENV#" public/configuration.json && \
  pnpm install && \
  pnpm run setup:vocabs vocab.json && \
  pnpm run build-only --base=/oni

###############################################################################
#
FROM nginx:1-alpine

WORKDIR /tmp

RUN mkdir /usr/share/nginx/html/oni

COPY --from=builder /tmp/oni-ui/dist /usr/share/nginx/html/oni

COPY docker/nginx-oni.conf /etc/nginx/conf.d/default.conf
