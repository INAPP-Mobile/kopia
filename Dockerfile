FROM kopia/kopia:0.23.1

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create app directories
RUN mkdir -p /app/repository /app/cache /app/logs

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
