FROM golang:1.24.8-bookworm AS builder

ARG MINIO_VERSION=RELEASE.2025-10-15T17-29-55Z

RUN CGO_ENABLED=0 go install "github.com/minio/minio@${MINIO_VERSION}"

FROM debian:12.12-slim

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 minio \
    && useradd --uid 10001 --gid minio --no-create-home minio \
    && mkdir -p /data \
    && chown minio:minio /data

COPY --from=builder /go/bin/minio /usr/local/bin/minio

USER minio

EXPOSE 9000 9001

ENTRYPOINT ["minio"]
CMD ["server", "/data", "--console-address", ":9001"]
