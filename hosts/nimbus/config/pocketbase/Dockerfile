FROM alpine:latest

ARG PB_VERSION=0.36.5
ARG TARGETARCH

RUN apk add --no-cache unzip ca-certificates

# Download the correct binary for the platform
RUN wget -q "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_${TARGETARCH}.zip" \
    -O /tmp/pb.zip \
    && unzip /tmp/pb.zip -d /pb/ \
    && rm /tmp/pb.zip \
    && chmod +x /pb/pocketbase

EXPOSE 8080

# pb_data   = SQLite DB + uploaded files
# pb_hooks  = JS hooks (optional)
# pb_migrations = schema migrations (optional)
VOLUME /pb/pb_data
VOLUME /pb/pb_hooks
VOLUME /pb/pb_migrations

HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/health || exit 1

CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8080"]
