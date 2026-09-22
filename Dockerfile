FROM alpine:3.20

ARG KOPIA_VERSION=0.23.1
RUN apk add --no-cache curl && \
    curl -sSL "https://github.com/kopia/kopia/releases/download/v${KOPIA_VERSION}/kopia-${KOPIA_VERSION}-linux-x64.tar.gz" | tar -xzf - -C /usr/local/bin kopia && \
    chmod +x /usr/local/bin/kopia && \
    apk del curl

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /app/repository /app/cache /app/logs

EXPOSE 51515

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
