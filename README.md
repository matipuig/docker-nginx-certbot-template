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

It's very important to add letsencrypt as a volume for each service (because there's where certbot will automatically save the certs) and link all services to app-network.
You can specify .env files for your images or set env variables in "environment" property.

In this case, I stored the SSL cert and key location in environment variables.
SSL certs and keys path have this format:

```
SERVER_SSL_CERT=/etc/letsencrypt/live/**my-site.com**/fullchain.pem;
SERVER_SSL_KEY=/etc/letsencrypt/live/**my-site.com**/privkey.pem;
```

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
      - ./env/app1.env
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

- CERTBOT_EMAIL: It's the mail that certbot will use to register the certs (required).

You will also find:

- #COMPOSE_CONVERTS_WINDOWS_PATH=1
- #COMPOSE_FORCE_WINDOWS_HOST=1
  These variables will be needed if you are running in Windows environment. They change from C:\dir\dir to /c/dir/dir...
  If you are using Windows, please check these sources:
  [https://medium.com/@Charles_Stover/fixing-volumes-in-docker-toolbox-4ad5ace0e572](https://medium.com/@Charles_Stover/fixing-volumes-in-docker-toolbox-4ad5ace0e572)
  [https://headsigned.com/posts/mounting-docker-volumes-with-docker-toolbox-for-windows/](https://headsigned.com/posts/mounting-docker-volumes-with-docker-toolbox-for-windows/)
  [https://github.com/docker/compose/issues/4240](https://github.com/docker/compose/issues/4240)
  [https://github.com/docker/compose/issues/4253](https://github.com/docker/compose/issues/4253)
  [https://github.com/docker/compose/pull/4026](https://github.com/docker/compose/pull/4026)

### 4. Set the webserver

The webserver contains nginx and certbot staticfloat's repo.
It's very important to add all the services in the nginx "depends_on" property (we need nginx to start last).
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
    - ./conf/nginx/nginx.conf:/etc/nginx/user.conf.d:ro
    - ./conf/nginx/passwords:/etc/nginx/passwords:ro
    - ./conf/nginx/logs:/etc/nginx/logs
    - ./conf/nginx/html:/etc/nginx/html
    - letsencrypt:/etc/letsencrypt
  networks:
    - app-network
  depends_on:
    - app1
    - app2
```

### 5. Configure nginx.

Normally configure nginx in conf/nginx/nginx.conf dir. You can use [nginx docs](https://nginx.org/en/docs/).
You should only care about locations and server_names (everything else is configured in the main conf file or in the template example).

SSL references will have this format:
ssl_certificate /etc/letsencrypt/live/**my-site.com**/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/**my-site.com**/privkey.pem;

You do not need to listen to 80 port (every request will be redirected to 443).

You can see my-site.conf:

```nginx
server {
    server_name my-site.com;

    # SSL configuration.
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/my-site.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/my-site.com/privkey.pem;
    include  /etc/nginx-ssl/options-ssl-nginx.conf;
    ssl_dhparam /etc/dhparam/ssl-dhparams.pem;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Slowloris protection.
    client_body_timeout 5s;
    client_header_timeout 5s;
    underscores_in_headers on;

     # Preventing DOS.
    limit_req zone=base_req_limiter burst=10 nodelay;
    limit_conn base_conn_limiter 100;
    limit_req_log_level notice;

    # Edit as needed.
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "no-referrer";
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; img-src * 'self'; frame-src *; connect-src 'self' ws: wss: https:; style-src 'self'; style-src-elem 'self'" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Feature-Policy "autoplay 'none'; camera 'none'" always;
    add_header X-Permitted-Cross-Domain-Policies "master-only" always;
    add_header Expect-CT "max-age=604800, enforce, report-uri='https://my-site.com/report'" always;
    fastcgi_hide_header "X-Powered-By";
    proxy_hide_header "X-Powered-By";

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

**SSL Protection:** Pay attention to use options-ssl-nginx.conf, ssl-dhparams and the add_header hsts lines. These lines sets the configuration to score A+ in [ssllabs.com](https://ssllabs.com).

**Headers protection**: Also, you can see a lot of "add_header" directives. These are different directives to increase security. If your webapp will take care of them, you can remove them or edit them according to your needs. For example, Content-Security-Policy will be more effective modified. You can check with pages like: [Mozilla Observatory](https://observatory.mozilla.org).

**DOS and slowloris protection**: There's also some configuration for limit_req and limit_conn to avoid DOS attacks. The base limit it's quite high, you should make it more restrictive for your use case. You can see more on this on: [https://www.nginx.com/blog/rate-limiting-nginx/](https://www.nginx.com/blog/rate-limiting-nginx/)

You will find another folders: logs (where the nginx logs will be displayed), html (where you can save the custom error pages) and passwords, when you can store all your passwords for auth basic.

### 6. Configure your docker-compose.yml with /additions dir.

You can add the services, volumes, networks, etc. you need. In this template, I added mongo just as an example.
You have some samples in the /additions dir. There's configuration for mongo, redis, mariadb/mysql, phpmyadmin, etc.
Each configuration has it's own readme file for usage.

### 7. Configure backup

The backup is made with [futurice/docker-volume-backup](https://hub.docker.com/r/futurice/docker-volume-backup) library. You can configure it as you wish (by default, it saves every backup in the backup folder at 4:00 AM).
In order to use it, you must add to "volumes" every volume you want to backup with the format: volume_name:/backup/volume_name:ro
For example, if you have a volume called wordpress, it should be: wordpress:/backup/wordpress:ro

```yml
backup:
  image: futurice/docker-volume-backup:latest
  environment:
    - BACKUP_SOURCES: /backup
    - BACKUP_FILENAME: backup-%Y-%m-%dT%H-%M-%S.tar.gz
    - BACKUP_ARCHIVE: /archive
    - BACKUP_CRON_EXPRESSION: "0 4 * * *"
    - TZ: America/Argentina/Buenos_Aires
  volumes:
    - letsencrypt:/backup/letsencrypt:ro
    - ./backups:/archive
```

You can use backup manually executing:
docker-compose exec backup ./backup.sh

### 8. (Optional) Protecting nginx with auth basic.

You can modify the conf/nginx/passwords files to ask for authentication for specific locations. This can add an extra layer of security.
File example:

Filename: conf/nginx/passwords/new-site

```
root:nQqwOK2bWAUGQ
```

In this case, the user is "root" and the password is "123456".
These are the docs for basic auth: [nginx docs](https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/).
Also, you can simply get an encrypted password using "openssl passwd" command.
Then, add it to nginx location:

```nginx
server {
    location /protected_url {
      auth_basic "Please provide login infomation.";
      auth_basic_user_file /etc/nginx/passwords/new-site;
      #...
    }
}
```

**Note:** Do NOT upload the password files to a repository.

### 9. (Optional) Protect nginx with IP whitelist.

You can use "allow" and "deny" nginx directives to create an IP whitelist.
In this case, 127.0.0.1 is the IP for localhost (but it could be any IP you want).
In this example, you can only access via localhost, and you should use a ssh tunnel to accomplish that:
ssh user@domain -L 8000:localhost:443 -N
From now on, you can access protected_url_with_tunnel in your local computer with: localhost:8000/protected_url_with_tunnel (which will go to localhost:443/protected_url_with_tunnel in the host).

**Note**: Replace "127.0.0.1" with your server IP.

```nginx
server {
    location /protected_url_with_tunnel {
      allow 127.0.0.1;
      deny all;
      auth_basic "Please provide login infomation.";
      auth_basic_user_file /etc/nginx/passwords/sample;
      #...
    }
}
```

## Issues

I tried these in Windows and Linux and I didn't have problems. If you have any issue, please, let me know.

## License

MIT © [Matías Puig](https://www.github.com/matipuig)
