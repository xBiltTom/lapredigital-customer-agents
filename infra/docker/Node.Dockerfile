# Node 24.22.3 / npm 11.19.1, imagen oficial verificada para T03.
FROM node:24-bookworm-slim@sha256:dc26ae92c9fb15cf6b1d63e20f0944b2efe0f115b20e00be48fb23fceb061c54 AS toolchain

ARG LOCAL_UID=1000
ARG LOCAL_GID=1000

RUN set -eu; \
    test "$LOCAL_UID" -gt 0; \
    test "$LOCAL_GID" -gt 0; \
    if [ "$LOCAL_GID" != "1000" ]; then groupmod -g "$LOCAL_GID" node; fi; \
    usermod -u "$LOCAL_UID" -g "$LOCAL_GID" node; \
    mkdir -p /workspace/node_modules /home/node/.npm; \
    chown -R node:node /workspace /home/node/.npm

ENV TZ=America/Lima
WORKDIR /workspace
USER node

CMD ["npm", "run", "check"]
