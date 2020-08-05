# Changes realized to this repo [staticfloat/docker-ningx-certbot](https://github.com/staticfloat/docker-nginx-certbot):

1. Changed one script in util.sh that was broken:
   last_renewal_sec=$(date --date="$(openssl x509 -startdate -noout -in \$last_renewal_file | cut -d= -f 2)" '+%s')

1. Changed the nginx default config for one more robust for production (original repo uses the nginx default config).

1. Added dhparam and nginx configuration from certbot repo to improve security (according to ssllabs.com qualification):
   https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
   https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem

1. Updated the dockerfile to include all this modifications in the image.

# License MIT

# [Matias Puig](https://www.github.com/matipuig)
