###############################################################################
#
FROM node:lts AS builder

ARG ROCRATE_API_ENDPOINT
ARG ROCRATE_API_CLIENTID
ARG BUMP=18

RUN corepack enable

WORKDIR /tmp

RUN git clone https://github.com/paradisec-archive/oni-ui.git -b paradisec

WORKDIR /tmp/oni-ui

COPY docker/oni.json src/configuration.json

RUN sed -i "s#ROCRATE_API_ENDPOINT#$ROCRATE_API_ENDPOINT#;s#ROCRATE_API_CLIENTID#$ROCRATE_API_CLIENTID#" src/configuration.json && \
  yarn install && \
  ls scripts && \
  node -v && \
  node --experimental-strip-types scripts/fetch-vocabs.mts vocab.json && \
  yarn run build --base=/oni

###############################################################################
#
FROM nginx:1-alpine

WORKDIR /tmp

RUN mkdir /usr/share/nginx/html/oni

COPY --from=builder /tmp/oni-ui/dist /usr/share/nginx/html/oni

COPY docker/nginx-oni.conf /etc/nginx/conf.d/default.conf
