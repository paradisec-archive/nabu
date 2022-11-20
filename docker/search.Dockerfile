FROM solr:8

USER solr

COPY solr/solr.xml /var/solr/data/
COPY solr/zoo.cfg /var/solr/data/
COPY solr/configsets /var/solr/data/configsets

COPY solr/production/core.properties /var/solr/data/production/
COPY solr/staging/core.properties /var/solr/data/staging/
