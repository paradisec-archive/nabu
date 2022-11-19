FROM solr:8

USER root

RUN rm -rf /opt/solr/server/solr

COPY solr/solr.xml /opt/solr/server/solr/
COPY solr/configsets /opt/solr/server/solr/configsets

RUN mkdir -p /opt/solr/server/solr/production/data
RUN mkdir -p /opt/solr/server/solr/staging/data

COPY solr/production/core.properties /opt/solr/server/solr/production
COPY solr/staging/core.properties /opt/solr/server/solr/staging

USER solr
