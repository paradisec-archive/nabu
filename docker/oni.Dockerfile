FROM ghcr.io/language-research-technology/oni-ui:new-api

#RUN touch bump-8

WORKDIR /

COPY docker/oni.json /configuration.json
RUN sed -i "s#ROCRATE_API_ENDPOINT#$ROCRATE_API_ENDPOINT#;s#ROCRATE_API_CLIENTID#$ROCRATE_API_CLIENTID#;s#SENTRY_ENV#$SENTRY_ENV#" /configuration.json

WORKDIR /usr/share/nginx/html

COPY docker/i18n . 
COPY app/assets/images/paradisec.jpg logo.jpg
