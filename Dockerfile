FROM alpine:3.19

LABEL maintainer="mayson@example.com"
LABEL version="2.0-final"

ENV WIKI_VERSION=2.5.303 \
    NODE_ENV=production

RUN apk add --no-cache \
    nodejs npm bash curl git python3 make g++ \
    postgresql-client ca-certificates tzdata \
    && rm -rf /var/cache/apk/*

RUN addgroup -g 1000 wiki && \
    adduser -D -u 1000 -G wiki wiki

RUN mkdir -p /wiki && chown wiki:wiki /wiki

USER wiki
WORKDIR /wiki

RUN wget -qO- https://github.com/Requarks/wiki/releases/download/v${WIKI_VERSION}/wiki-js.tar.gz | tar xz

RUN npm install --omit=dev --legacy-peer-deps

COPY --chown=wiki:wiki start-wiki.sh /wiki/start-wiki.sh

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s \
    CMD curl -f http://localhost:3000/healthz || exit 1

CMD ["/wiki/start-wiki.sh"]
