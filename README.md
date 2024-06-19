# Enhanced Nginx

> Documentation in progress

The script to generate the config for Cloudflare is taken from here: https://github.com/ergin/nginx-cloudflare-real-ip

Nginx Docker container with standalone certbot and automatic update of Cloudflare IP address ranges.

## How it works

Instead of agonizing with certbot + nginx + well-known/acme-challenge, let's just let certbot do its job in standalone mode.

When the container is started for the first time, certbot will bring up its server, issue and fail certificates. And then at the very end nginx will start up.

When restarting the container, certbot will check the existing certificate for expiration, and if the expiration is ok, it will just not do anything, nginx will start right away.

## Usage

1. Specify 2 volumes for nginx and letsencrypt 
2. Mount your site config to container. You can mount multiple sites

You should use the following lines in your nginx config for the site. `REPLACEMENT_CERT_NAME` will be replaced by the name of the certificate you pass to the container.

```nginx configuration
  ssl_certificate         /etc/letsencrypt/live/REPLACEMENT_CERT_NAME/fullchain.pem;
  ssl_certificate_key     /etc/letsencrypt/live/REPLACEMENT_CERT_NAME/privkey.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/REPLACEMENT_CERT_NAME/chain.pem;
```

If you want to serve multiple domains within a container, list their domains in the `SITE_DOMAINS` environment variable. A common certificate will be issued for them.

### Directories for your configs

You can include your configuration via mounting configs to container's special paths. It could be virtual server blocks or additional `http` section configuration (such as `log_format` directive). 

| Path                    | Description                                              |
|-------------------------|----------------------------------------------------------|
| `/nginx-config/conf/`   | Will be included into `http` section of the Nginx config |
| `/nginx-config/stream/` | -> `stream` section                                      |

### Example

For Docker Compose:

```yaml filename="docker-compose.yml"
volumes:
  nginx_data:
  letsencrypt_data:

services:
  nginx:
    image: ghcr.io/fedorov-xyz/enhanced-nginx:latest
    ports:
      - 80:80
      - 443:443
    volumes:
      - nginx_data:/etc/nginx/data
      - letsencrypt_data:/etc/letsencrypt
      - ./example.com.conf:/nginx-config/conf/example.com.conf
    environment:
      - SITE_DOMAINS=example.com,staging.example.com
      - CERT_NAME=example.com
      - CERTBOT_EMAIL=your@email.com
      - CERTBOT_TEST_CERT=true
```

## Environment variables list

| Variable             | Requirded | Description                                                  |
|----------------------|-----------|--------------------------------------------------------------|
| `SITE_DOMAINS`       | yes       | Сomma-separated list of domains for Let's Encrypt certificate |
| `CERT_NAME`          | yes       | Certificate name.                                            |
| `CERTBOT_EMAIL`      | yes       | Email for Let's Encrypt.                                     |
| `CERTBOT_TEST_CERT`  |           | Pass `true` for test certificates.                           |
