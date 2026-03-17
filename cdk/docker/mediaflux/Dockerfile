FROM node:24-slim

ARG MF_CLIENT_VERSION=0.8.5
ARG MF_CLIENT_URL=https://gitlab.unimelb.edu.au/resplat-mediaflux/releases/raw/master/mediaflux/unimelb-mf-clients-${MF_CLIENT_VERSION}-linux-x64.tar.gz

RUN apt-get update && apt-get install --no-install-recommends -y \
  wget ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download and set up MediaFlux client
RUN wget -q "$MF_CLIENT_URL" \
  && tar -xzf "unimelb-mf-clients-${MF_CLIENT_VERSION}-linux-x64.tar.gz" \
  && rm "unimelb-mf-clients-${MF_CLIENT_VERSION}-linux-x64.tar.gz" \
  && mv ./* mf

# NOTE: https://gitlab.unimelb.edu.au/resplat-mediaflux/unimelb-mf-clients/-/blob/master/README.md#system-environment-variables
ENV MFLUX_HOST=mediaflux.researchsoftware.unimelb.edu.au
ENV MFLUX_PORT=443
ENV MFLUX_DOMAIN=local
ENV MFLUX_TRANSPORT=https

# Install Node dependencies
COPY package.json /app/package.json
RUN corepack enable pnpm && pnpm install --prod

COPY archive.ts /app/archive.ts
COPY inventory.ts /app/inventory.ts

CMD ["node", "/app/archive.ts"]
