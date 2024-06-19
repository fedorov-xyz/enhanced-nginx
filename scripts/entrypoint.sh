#!/bin/bash

# Static
mkdir -p /etc/nginx/data

CLOUDFLARE_FILE_PATH=/etc/nginx/data/cloudflare.conf
DHPARAMS_FILE_PATH=/etc/nginx/data/dhparam.pem

# External
: "${SITE_DOMAINS:?Must provide SITE_DOMAINS in environment}"
: "${CERT_NAME:?Must provide CERT_NAME in environment}"
: "${CERTBOT_EMAIL:?Must provide CERTBOT_EMAIL in environment}"

echo "Init nginx container"

# Generate dhparam.pem
if [ ! -f $DHPARAMS_FILE_PATH ]; then
    echo "Generate dhparam.pem"
    openssl dhparam -out $DHPARAMS_FILE_PATH 2048
    chmod 600 $DHPARAMS_FILE_PATH
fi

# Generate Cloudflare IP ranges
if [ ! -f $CLOUDFLARE_FILE_PATH ]; then
    echo "Generate Cloudflare IP ranges config"
    /usr/local/bin/update_cloudflare_ips.sh
fi

# Create user config directories in case they have not been mounted into the container

mkdir -p /nginx-config/conf
mkdir -p /nginx-config/stream

# Copy user configs

mkdir -p /etc/nginx/conf.d
mkdir -p /etc/nginx/stream.d

cp -r /nginx-config/conf/* /etc/nginx/conf.d/ 2>/dev/null
cp -r /nginx-config/stream/* /etc/nginx/stream.d/ 2>/dev/null

# Applying replacements for site configs

declare -a replacements=(
  "CERT_NAME"
)

for env in "${replacements[@]}"
do
   if [ -n "${!env}" ]; then
      replacement=$(printf "%s" "${!env}" | sed 's/[,\/&]/\\&/g')  # Escape special characters in the replacement value
      for file in /etc/nginx/conf.d/*; do
          sed -i "s,REPLACEMENT_$env,$replacement,g" "$file" || exit
      done
   fi
done

# Check cert exist
if [ ! -f /etc/letsencrypt/live/"$CERT_NAME"/fullchain.pem ]; then
    echo "Certificate $CERT_NAME do not exists, will generate it now"
fi

echo "Running certbot"

certbot_args=(
  certonly
  --standalone
  --renew-by-default
  --non-interactive
  --agree-tos
  --cert-name "$CERT_NAME"
  --email "$CERTBOT_EMAIL"
  -d "$SITE_DOMAINS"
)

if [ "$CERTBOT_TEST_CERT" = "true" ]; then
    echo "Using staging (test) certificate"
    certbot_args+=(--test-cert)
fi

certbot "${certbot_args[@]}" || exit

echo "Start nginx"
nginx -g "daemon off;"
