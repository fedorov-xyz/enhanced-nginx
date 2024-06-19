FROM nginx:1.26.0

LABEL org.opencontainers.image.source="https://github.com/fedorov-xyz/nginx"

RUN apt-get update && apt-get install --no-install-recommends -y \
        nano \
        curl \
        cron \
        certbot \
        tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /etc/nginx/

# Remove default conf as we don't use it
RUN rm -rf conf.d

COPY nginx/nginxconfig.io/ ./nginxconfig.io
COPY nginx/nginx.conf .

COPY scripts/entrypoint.sh /
RUN ["chmod", "+x", "/entrypoint.sh"]

COPY scripts/update_cloudflare_ips.sh /usr/local/bin/update_cloudflare_ips.sh
RUN chmod +x /usr/local/bin/update_cloudflare_ips.sh

COPY cron/crontab /etc/cron.d/crontab
RUN chmod 0644 /etc/cron.d/crontab
RUN crontab /etc/cron.d/crontab
RUN touch /var/log/cron.log

# Запуск cron и nginx
CMD ["/entrypoint.sh"]
