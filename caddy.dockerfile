FROM caddy:2.4.6-builder-alpine as builder

RUN xcaddy build --with github.com/corazawaf/coraza-caddy

FROM caddy:2.4.6-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy