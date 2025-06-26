FROM nginx:alpine

COPY docker/sentry-nginx.conf /etc/nginx/conf.d/default.conf
