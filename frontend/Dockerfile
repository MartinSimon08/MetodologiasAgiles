# Servidor de desarrollo de Vite para docker compose.

FROM node:24.18.0-bookworm-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y util-linux && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    npm install -g pnpm@12.6.0

WORKDIR /app

COPY docker-entrypoint /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
CMD ["pnpm", "dev"]
