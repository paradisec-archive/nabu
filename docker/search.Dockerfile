FROM solr:7.7.2

RUN rm -rf /opt/solr/server/solr

COPY --chown=solr:solr solr/solr.xml /opt/solr/server/solr/
COPY --chown=solr:solr solr/configsets /opt/solr/server/solr/configsets

RUN mkdir -p /opt/solr/server/solr/production/data

COPY --chown=solr:solr solr/production/core.properties /opt/solr/server/solr/production
