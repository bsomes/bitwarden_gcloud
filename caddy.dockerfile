FROM caddy:builder-alpine as builder

RUN xcaddy build --with github.com/corazawaf/coraza-caddy

FROM caddy:alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy