# Add adminer to the compose

This dockerfile is modified to NOT allow the login of root user.
**Note**: This image it's not working with mongo. If you want to use mongoDB use mongo-express UI.

```
FROM adminer:latest

# Disable login for root user.
RUN  replace="\AdminerPlugin {" && \
  replacement="\AdminerPlugin {function login(\$login, \$password){\$login = strtolower(\$login); return (\$login != \"root\");\}" && \
  sed -i "s/${replace}/${replacement}/" /var/www/html/index.php
```

This image is based on the oficial adminer image and modifies index.php in order to prevent root user login.

**Note:** This container is protected following [these recommendations](https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-phpmyadmin-with-nginx-on-an-ubuntu-18-04-server). Read them to understand what's going on here.
They are for phpmyadmin, but they also apply for adminer.

## Usage:

Copy the admin container into the service section of the docker-compose.yml file.

- Add databases images in the "depends_on" parameter (do not start adminer before mysql).
- Never expose ports 80 or 8080 (ports: "80:80" or "8080:800") of adminer in docker-compose.yml. **Always hide it behind nginx proxy, adminer is weak against brute force.**
- Modify the nginx location configuration. If you use /adminer/, you should put the same in the "rewrite" line inside the /location section (rewrite ^/adminer(/.\*)$ $1 break;). Otherwise, adminer will response with 404 error.
  **Note:** The url shouldn't be "/adminer" because it's too easy for bots to find.
- **Protect the URL with "auth_basic"** and establish where the auth_basic_user_file is. This adds an extra layer of security (preventing brute force).
- **Protect the URL with IP whitelist**. You can uncomment and use allow/deny for IPs. If you have some specific IP, you can use it here. Also, you could make use of an SSH tunnel for extra security: (ssh user@domain -L 8000:localhost:443) and then allow only localhost IP through SSH tunell, like a VPN.

## Example:

Filename: mysite.conf

```nginx
    # This line is necessary to access via "/LOCATION". If you don't add it, it will return "forbidden" in /LOCATION.
    location = /LOCATION {
        rewrite /LOCATION /LOCATION/ redirect;
    }
    location /LOCATION {
#        allow YOUR_IP_HOST;
#        deny all;
        rewrite ^/LOCATION(.*)$ $1 break;
        auth_basic "Login information.";
        auth_basic_user_file /etc/nginx/passwords/sample;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $http_host;
        proxy_pass http://adminer:8080;
        proxy_redirect off;
    }
```
