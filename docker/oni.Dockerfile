###############################################################################
#
FROM node:lts AS builder

ARG ROCRATE_API_ENDPOINT
ARG ROCRATE_API_CLIENTID
ARG BUMP=6

RUN corepack enable

WORKDIR /tmp

RUN git clone https://github.com/paradisec-archive/oni-ui.git -b paradisec

WORKDIR /tmp/oni-ui

COPY docker/oni.json configuration.json

RUN sed -i "s/ROCRATE_API_ENDPOINT/$ROCRATE_API_ENDPOINT/;s/ROCRATE_API_CLIENTID/$ROCRATE_API_CLIENTID/" configuration.json && \
  yarn install && \
  npm build --base=/oni

###############################################################################
#
FROM nginx:1-alpine

WORKDIR /tmp

COPY --from=builder /tmp/oni-ui/dist /usr/share/nginx/html

RUN sed -i '/server {/a \  location /oni/ {\n     try_files $uri $uri/ /oni/index.html;\n    alias /usr/share/nginx/html;\n    }' /etc/nginx/conf.d/default.conf
