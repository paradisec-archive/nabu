FROM ghcr.io/paradisec-archive/proxyist:v0.2.17

COPY docker/proxyist.config.prod.js /usr/src/app/proxyist.config.js

ENV PROXYIST_ADAPTER_NAME="@paradisec/proxyist-adapter-s3"
