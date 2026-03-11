FROM ubuntu:24.04

ARG MF_CLIENT_VERSION=0.8.5
ARG MF_CLIENT_URL=https://gitlab.unimelb.edu.au/resplat-mediaflux/releases/raw/master/mediaflux/unimelb-mf-clients-${MF_CLIENT_VERSION}-linux-x64.tar.gz
ARG AWS_CLI_URL=https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip

RUN apt-get update && apt-get install --no-install-recommends -y \
  wget unzip ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app


RUN wget "$MF_CLIENT_URL" \
  && tar -xzf "unimelb-mf-clients-${MF_CLIENT_VERSION}-linux-x64.tar.gz" \
  && rm "unimelb-mf-clients-${MF_CLIENT_VERSION}-linux-x64.tar.gz" \
  && mv * mf


RUN <<EOF
  for i in mf/bin/unix/unimelb-mf-*; do
    name=$(basename $i | sed 's/unimelb-mf-//')
    ln -s $i $name
  done
EOF

RUN cd /tmp && \
  wget $AWS_CLI_URL && \
  unzip awscli-exe-linux-x86_64.zip && \
  ./aws/install && \
  rm -rf /tmp/awscli-exe-linux-x86_64.zip /tmp/aws


# NOTE: https://gitlab.unimelb.edu.au/resplat-mediaflux/unimelb-mf-clients/-/blob/master/README.md#system-environment-variables
ENV MFLUX_HOST=mediaflux.researchsoftware.unimelb.edu.au
ENV MFLUX_PORT=443
ENV MFLUX_DOMAIN=local

ENV MFLUX_TRANSPORT=https

COPY archive.sh /app/archive.sh
RUN chmod +x /app/archive.sh

CMD ["/app/archive.sh"]
