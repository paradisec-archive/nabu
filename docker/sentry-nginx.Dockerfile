FROM nginx:alpine

COPY sentry-nginx.conf /etc/nginx/conf.d/default.conf
