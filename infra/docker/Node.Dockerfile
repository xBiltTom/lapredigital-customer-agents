# Node 24.22.3 / npm 11.19.1, imagen oficial verificada para T03.
FROM node:24-bookworm-slim@sha256:dc26ae92c9fb15cf6b1d63e20f0944b2efe0f115b20e00be48fb23fceb061c54 AS toolchain

ARG LOCAL_UID=1000
ARG LOCAL_GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
    dbus-bin gnome-keyring libsecret-tools \
    && rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    test "$LOCAL_UID" -gt 0; \
    test "$LOCAL_GID" -gt 0; \
    if [ "$LOCAL_GID" != "1000" ]; then groupmod -g "$LOCAL_GID" node; fi; \
    usermod -u "$LOCAL_UID" -g "$LOCAL_GID" node; \
    mkdir -p /workspace/node_modules /workspace/apps/server/.eve /home/node/.npm /home/node/.local/share/keyrings; \
    chown -R node:node /workspace /home/node/.npm /home/node/.local

ENV TZ=America/Lima
WORKDIR /workspace
USER node

CMD ["npm", "run", "check"]

# Artefactos del MVP, sin bind mounts ni secretos del equipo.
FROM toolchain AS mvp-build
ENV AI_PROVIDER=chatgpt
COPY --chown=node:node package.json package-lock.json .npmrc ./
COPY --chown=node:node apps/server ./apps/server
COPY --chown=node:node apps/web ./apps/web
RUN --mount=type=cache,target=/home/node/.npm,uid=1000,gid=1000 npm ci --no-audit --no-fund
RUN npm run build:web && npm run build:server

FROM toolchain AS mvp-runtime
ENV AI_PROVIDER=chatgpt WEB_DIST_DIR=/workspace/apps/web/.dist
COPY --from=mvp-build --chown=node:node /workspace/package.json ./package.json
COPY --from=mvp-build --chown=node:node /workspace/node_modules ./node_modules
COPY --from=mvp-build --chown=node:node /workspace/apps/server/package.json ./apps/server/package.json
COPY --from=mvp-build --chown=node:node /workspace/apps/server/.eve/packaged ./apps/server/.eve/packaged
COPY --from=mvp-build --chown=node:node /workspace/apps/web/.dist ./apps/web/.dist
COPY --chown=node:node scripts/eve-local ./scripts/eve-local
EXPOSE 3000
CMD ["npm","run","start:server"]
