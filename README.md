# docker-nginx-certbot-template

This repo is a template built on the @staticfloat's repo [docker-nginx-certbot](https://github.com/staticfloat/docker-nginx-certbot) (**Awesome work!!!**).
You can configure nginx and it will automatically cert and renew the different domains specified in the nginx .conf files.
It's also configured for production and get an A+ in [ssllabs](https://www.ssllabs.com).

This template is prepared to have many apps using nginx as a reverse proxy (in this example, there are two equal apps working in different folders and an nginx config file to show how).


## How to use

### 1. Add your apps.

Add the different apps you will need in the apps directory.
You have /app1 and /app2 written in node to test (in /apps/app1 and /apps/app2).
Dockerfiles should be accessed like: /apps/app1/dockerfile and /apps/app2/dockerfile.

### 2. Add the services to docker-compose.yml

It's very important to add letsencrypt as a volume (because there's were certbot will automatically save the certs) and link all services to app-network.
You can specify .env files for your images or set env variables in "environment" property.

In this case, I stored the SSL cert and key location in environment variables.
SSL certs and keys path have this format:
SERVER_SSL_CERT=/etc/letsencrypt/live/**my-site**/fullchain.pem;
SERVER_SSL_KEY=/etc/letsencrypt/live/**my-site.com**/privkey.pem;
And use them in the node apps.

```yml
services:
  app1:
    container_name: app1
    restart: always
    build:
      context: ./apps/app1
      dockerfile: dockerfile
    env_file:
      - app1.env
    environment:
      - PORT=443
      - NAME=First app
    volumes:
      - letsencrypt:/etc/letsencrypt
    networks:
      - app-network
    depends_on:
      - mongo
```

### 3. Set the .env file for docker-compose

This file contains the environment variables that docker-compose will use at building time.
In this case there are two:

- CERTBOT_EMAIL: It's the mail that certbot will use to register the certs (required).
- CURRENT_DIRECTORY: It's the actual directory where the docker-compose file is (required). It's used this way to create the nginx volume. There are also two more variables you should need to change if you are using Windows ( COMPOSE_CONVERTS_WINDOWS_PATH and COMPOSE_FORCE_WINDOWS_HOST, commented in the file). In my case, path would be: /home/my-site/ or C:\\users\\my-site\\.
  Note: Be careful, sometimes bind mounts are tricky about paths...

### 4. Set the webserver

The webserver contains nginx and certbot staticfloat's repo.
It's very important to add all the services that will need an SSL in the "depends_on" property (we need nginx to start last).
Otherwise, nginx could start before them and will fail when it tries to connect to a non-existent server.

```yml
webserver:
  container_name: webserver
  restart: unless-stopped
  build:
    context: ./nginx-certbot
    dockerfile: dockerfile
  ports:
    - "80:80/tcp"
    - "443:443/tcp"
  environment:
    CERTBOT_EMAIL: ${CERTBOT_EMAIL}
  volumes:
    - ${CURRENT_DIRECTORY}nginx.conf:/etc/nginx/user.conf.d:ro
    - letsencrypt:/etc/letsencrypt
  networks:
    - app-network
  depends_on:
    - app1
    - app2
```

### 5. Configure nginx.

Normally configure nginx in /nginx.conf dir. You can use [nginx docs](https://nginx.org/en/docs/).
You should only care about locations and server_names (everything else is configured in the main conf file or in the template example).

Pay attention to server_name, ssl_certificate and ssl_certificate_key.
SSL references will have this format:
ssl_certificate /etc/letsencrypt/live/**my-site.com**/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/**my-site.com**/privkey.pem;

You do not need to listen to 80 port (every request will be redirected to 443).

You can see my-site.conf:

```nginx
server {
    server_name my-site.com;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/my-site.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/my-site.com/privkey.pem;
    include  /etc/nginx-ssl/options-ssl-nginx.conf;
    ssl_dhparam /etc/dhparam/ssl-dhparams.pem;

    client_body_timeout 5s;
    client_header_timeout 5s;
    underscores_in_headers on;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $http_host;
        proxy_pass https://app1:443/;
        proxy_redirect off;
    }

    location /app2/ {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $http_host;
        proxy_pass https://app2:443/;
        proxy_redirect off;
    }
}
```

### 6. Normally configure your docker-compose.yml

You can add the services, volumes, networks, etc. you need. In this template, I added mongo just as an example.
