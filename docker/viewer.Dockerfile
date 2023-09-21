###############################################################################
#
FROM node:16-stretch AS builder

WORKDIR /tmp
RUN git clone https://github.com/nabu-catalog/nabu-collection-viewer-v1.git

WORKDIR /tmp/nabu-collection-viewer-v1
RUN npm install --ignore-scripts
RUN cd node_modules \
  && rm -rf imageviewer \
  && git clone https://github.com/amritk/ImageViewer.git \
  && mv ImageViewer/ imageviewer

RUN ./node_modules/.bin/webpack  --config webpack.deploy.production.js

###############################################################################
#
FROM nginx

WORKDIR /tmp
RUN mkdir /usr/share/nginx/html/viewer
COPY --from=builder /tmp/nabu-collection-viewer-v1/dist /usr/share/nginx/html/viewer
