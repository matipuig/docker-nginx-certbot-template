# Index

- [Index](#index)
- [Docker Nginx Certbot Template](#docker-nginx-certbot-template)
  - [How to use](#how-to-use)
    - [1. Add your apps.](#1-add-your-apps)
    - [2. Add the services to docker-compose.yml](#2-add-the-services-to-docker-composeyml)
    - [3. Set the .env file for docker-compose](#3-set-the-env-file-for-docker-compose)
    - [4. Set the webserver](#4-set-the-webserver)
    - [5. Configure nginx.](#5-configure-nginx)
    - [6. Configure your docker-compose.yml with /additions dir.](#6-configure-your-docker-composeyml-with-additions-dir)
    - [7. Configure backup](#7-configure-backup)
    - [8. (Optional) Protecting nginx with auth basic.](#8-optional-protecting-nginx-with-auth-basic)
    - [9. (Optional) Protect nginx with IP whitelist.](#9-optional-protect-nginx-with-ip-whitelist)
  - [Security considerations](#security-considerations)
    - [Reverse proxy](#reverse-proxy)
    - [Databases](#databases)
    - [Database managers](#database-managers)
    - [Applications](#applications)
  - [Issues](#issues)
  - [License](#license)

# Docker Nginx Certbot Template

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
SSL certs and keys path with certbot have this format:

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

**Note**: If you have your own certificates and you don't want to use certbot, you can use the mounted volume "conf/nginx/certs", which will mount them to "/certs".
This way, you can add your own certificates to nginx configuration. **Do NOT upload certificates or keys to any repository.**

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

  It also happened, in kitematic, that the volume won't work if the path is not complete. For example: c:\\\\Users\\\\User\\\\docker/something/something And also is case sensitive.

### 4. Set the webserver

The webserver contains nginx and certbot staticfloat's repo.
It's very important to add all the services in the nginx "depends_on" property (we need nginx to start last).
Otherwise, nginx could start before them and will fail when it tries to connect to a non-existent server.

How to configure:

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

**Important Note in Windows**:
If often happens in windows that the mounting won't work if you don't set the complete path (or activate the env variable. Please see previous section). And you will find the docker container starts, but your files are not as you expect. So, you won't see any error, but the files are not inside the container.
Sometimes ./var:/var:rw works (like in Linux), but other times worked for us like:

- c:\\\\Users\\\\User\\\\docker\\\\var:/var
- c:\\\\Users\\\\User\\\\docker/var:/var
- //c/Users/User/docker/var:/var

You can see if the problem is the mounting looking for the specified files inside the container using bash:

```bash
docker-compose up -d webserver
docker exec -it webserver bash
cd /var && ls
# Are here my files? If don't, then probably the problem is the mounting...
```

### 5. Configure nginx.

Normally configure nginx in conf/nginx/nginx.conf dir. You can use [nginx docs](https://nginx.org/en/docs/). Algo, this document from DigitalOcean is excelent: [doc](https://www.digitalocean.com/community/tutorials/understanding-nginx-server-and-location-block-selection-algorithms).
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

**Proxies**:
If you want to proxy only a part of the url, remember to use the trailing slash. In order to achieve it, you should also add a redirect with the trailing slash.

```nginx
    location = /your-app {
      rewrite /your-app /your-app/ redirect;
    }
    location /your-app/ {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $http_host;
        proxy_pass http://your-app/;
        proxy_redirect off;
    }
```

Also, if you want your app to take care of the headers and not nginx, you can add a dummy add_header in the location section. It will leave the headers control to the app.

```nginx
    location /your-app/ {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $http_host;
      	add_header App "App" always;
        proxy_pass http://your-app/;
        proxy_redirect off;
    }
```

**SSL Protection:** Pay attention to use options-ssl-nginx.conf, ssl-dhparams and the add_header hsts lines. These lines sets the configuration to score A+ in [ssllabs.com](https://ssllabs.com).

**Headers protection**: Also, you can see a lot of "add_header" directives. These are different directives to increase security. If your webapp will take care of them, you can remove them or edit them according to your needs. For example, Content-Security-Policy will be more effective modified. You can check with pages like: [Mozilla Observatory](https://observatory.mozilla.org).

**DOS and slowloris protection**: There's also some configuration for limit_req and limit_conn to avoid DOS attacks. The base limit it's quite high, you should make it more restrictive for your use case. You can see more on this on: [https://www.nginx.com/blog/rate-limiting-nginx/](https://www.nginx.com/blog/rate-limiting-nginx/)

You will find another folders: logs (where the nginx logs will be displayed), html (where you can save the custom error pages) and passwords, when you can store all your passwords for auth basic.

### 6. Configure your docker-compose.yml with /additions dir.

You can add the services, volumes, networks, etc. you need. In this template, I added mongo just as an example.
You have some samples in the /additions dir. There's configuration for mongo, redis, mariadb/mysql, phpmyadmin, etc.
Each configuration has it's own readme file for usage and were prepared to use in production considering security best practices.

**Note**: Remember you might need to change the version of the images you use. All of them are with the "latest" version, but that might not be the best for production.
You can look for the recommended images in dockerhub.

**Some security guidelines**:

- Always change the image you use for another than "latest" (in production this can be dangerous).
- Never run the containers as the root user.
- Do not use a complete image if it's not necesary. For example, if you can use alpine, use alpine.
- Always use oficial images in dockerhub.
- Yse the hadolint tool online for best practices: [hadolint](https://hadolint.github.io/hadolint/).

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

## Security considerations

### Reverse proxy

- Using a reverse proxy as the entrypoint for your website its recommended. So, the only entrypoint and exposed ports should be 80 and 443 with TCP of nginx.
- Protect with auth_basic every application or URL that might be dangerous. Also, use a whitelist to prevent different IPs accessing your app.

### Databases

- Databases should never expose their ports to be accesed. For example, 3306 in MariaDB must always be protected. Other way, it could leave the database exposed to a brute force attack. Even if you are protected by a reverse proxy with some request rate, it creates a risk. The consequences of having the root user stolen would be terrible.
- If you have to expose your database (not recommended), then you should disable the root user. This way, you should only login with an user with less privileges and harder to guess (security trough obscurity it's not a good technique...).
- You might need to keep the root user, even though it's recommended to disable it. For example, you might need it in some databases to see performance issues (like in MariaDB).
- Apps shouldn't use root user for the database. It's recommended to have a less privileged user for each app.

### Database managers

- If you have to use a database manager (like PhpMyAdmin or Adminer), first of all, disable root user login at any cost. If it's that important to see something with the root user, then you should interact by the CLI. The root user is the easiest to guess (you only have to guess the password) and it also has high privileges.
- Never expose the database managers ports directly, like "8080:8080". Use a reverse proxy instead. This way you can protect the app against brute force attacks with a rate limiter and also add more security with more layers like auth_basic.
- If it's possible, add a whitelist with only localhost as the allowed IP. This way you can prevent any IP to access your database manager. If you don't have a VPN, or you cannot access as localhost, you can use a [SSH tunnel](https://www.ssh.com/ssh/tunneling/example).
- Do not use a database managers if you can.

### Applications

- If you use something like Node, do NOT use a process manager like pm2 to restart it all the time. It's better to exit the application with the error exit code and leave the restarting decision to docker-compose. If you need pm2 to run different processes at the same time, look if they shouldn't be in different containers.
- If you need a database, do NOT use the root user. Use an user with less privileges instead.
- Even if the apps takes care of themselves against brute force, DOS, etc., you should protect your application with a reverse proxy. A reverse proxy like nginx will let you add security layers to specific sections of your app, and also centralize the security. The main part where the app should take care of security is in headers (if it doesn't, use the reverse proxy), because it's the app who wknows its CSP, frame options, etc.

## Issues

I tried these in Windows and Linux and I didn't have problems. If you have any issue, please, let me know.

## License

MIT © [Matías Puig](https://www.github.com/matipuig)
