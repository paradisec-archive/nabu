FROM solr:8

USER root

RUN echo 'chown -R solr:solr /var/solr/mnt/*' > /docker-entrypoint-initdb.d/perms.sh
RUN echo 'rm /var/solr/mnt/*/index/write.lock' > /docker-entrypoint-initdb.d/write.sh

USER solr

COPY --chown=solr:solr solr/solr.xml /var/solr/data/
COPY --chown=solr:solr solr/zoo.cfg /var/solr/data/
COPY --chown=solr:solr solr/configsets /var/solr/data/configsets

COPY --chown=solr:solr solr/production/core.properties /var/solr/data/production/
COPY --chown=solr:solr solr/staging/core.properties /var/solr/data/staging/

RUN mkdir -p /var/solr/mnt/production /var/solr/mnt/staging

RUN ln -nfs /var/solr/mnt/production /var/solr/data/production/data
RUN ln -nfs /var/solr/mnt/staging /var/solr/data/staging/data
