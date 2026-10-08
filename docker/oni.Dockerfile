FROM ghcr.io/crate-works/oni:3

ENV BUMP=12

WORKDIR /usr/share/nginx/html

COPY oni.json /configuration.json
COPY i18n i18n
COPY paradisec.jpg logo.jpg
COPY redirects.conf /etc/nginx/oni.d/01-redirects.conf
