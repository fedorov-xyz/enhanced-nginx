#!/bin/bash

CLOUDFLARE_FILE_PATH=/etc/nginx/data/cloudflare.conf

echo "# Cloudflare IP ranges" > $CLOUDFLARE_FILE_PATH;
echo "" >> $CLOUDFLARE_FILE_PATH;

echo "# - IPv4" >> $CLOUDFLARE_FILE_PATH;
for i in $(curl -s -L https://www.cloudflare.com/ips-v4); do
  echo "set_real_ip_from $i;" >> $CLOUDFLARE_FILE_PATH;
done

echo "" >> $CLOUDFLARE_FILE_PATH;
echo "# - IPv6" >> $CLOUDFLARE_FILE_PATH;
for i in $(curl -s -L https://www.cloudflare.com/ips-v6); do
  echo "set_real_ip_from $i;" >> $CLOUDFLARE_FILE_PATH;
done

echo "" >> $CLOUDFLARE_FILE_PATH;
echo "real_ip_header CF-Connecting-IP;" >> $CLOUDFLARE_FILE_PATH;

# Test configuration
nginx -t;

if [ "$1" = "restart_nginx" ]; then
  systemctl reload nginx;
fi
