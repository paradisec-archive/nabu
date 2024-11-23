###############################################################################
#
FROM node:lts AS builder

ARG ONI_API_CLIENTID
ARG ONI_API_CLIENTSECRET
ARG BUMP=6

WORKDIR /tmp
RUN git clone https://github.com/paradisec-archive/oni-ui.git && cd oni-ui && git switch paradisec

WORKDIR /tmp/oni-ui/portal
COPY docker/oni.json configuration.json
RUN sed -i "s/ONI_API_CLIENTID/$ONI_API_CLIENTID/;s/ONI_API_CLIENTSECRET/$ONI_API_CLIENTSECRET/" configuration.json
RUN sed -i "s/publicPath: .*/publicPath: '\/oni',/" webpack-production.js
RUN npm run build

###############################################################################
#
FROM nginx

WORKDIR /tmp
RUN mkdir /usr/share/nginx/html/oni
COPY --from=builder /tmp/oni-ui/portal/dist /usr/share/nginx/html/oni
RUN sed -i '/server {/a \  location /oni/ {\n     try_files $uri $uri/ /oni/index.html;\n    alias /usr/share/nginx/html/oni/;\n    }' /etc/nginx/conf.d/default.conf
