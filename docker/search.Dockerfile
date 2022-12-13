FROM solr:8

USER solr

COPY --chown=solr:solr solr/solr.xml /var/solr/data/
COPY --chown=solr:solr solr/zoo.cfg /var/solr/data/
COPY --chown=solr:solr solr/configsets /var/solr/data/configsets

COPY --chown=solr:solr solr/production/core.properties /var/solr/data/production/
COPY --chown=solr:solr solr/staging/core.properties /var/solr/data/staging/
