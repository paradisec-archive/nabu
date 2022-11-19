FROM solr:8

USER root

RUN rm -rf /opt/solr/server/solr

USER solr

COPY --chown=solr:solr solr/solr.xml /var/solr/data/
COPY --chown=solr:solr solr/configsets /var/solr/data/configsets

RUN mkdir -p /var/solr/data/production/data
RUN mkdir -p /var/solr/data/staging/data

COPY --chown=solr:solr solr/production/core.properties /var/solr/data/production
COPY --chown=solr:solr solr/staging/core.properties /var/solr/data/staging
