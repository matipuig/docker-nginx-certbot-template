# Add phpmyadmin to the compose

**Note:** This container is protected following [these recommendations](https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-phpmyadmin-with-nginx-on-an-ubuntu-18-04-server). Read them to understand what's going on here.

## Usage:

Copy the phpmyadmin container into the service section of the docker-compose.yml file.

- Modify the environment variable PMA_ABSOLUTE_URI with the absolute URI phpmyadmin will have. Vg: https://yourserver.com/phpmyadmin/ (you can get this from nginx.conf).
- Never expose ports 80 or 8080 (ports: "80:80" or "8080:80") of phpmyadmin in docker-compose.yml. **Always hide it behind nginx proxy, phpmyadmin is weak against brute force.**
- Modify the nginx location configuration. If you use /phpmyadmin/, you should put the same in the "rewrite" line inside the /location section (rewrite ^/phpmyadmin(/.\*)$ $1 break;). Otherwise, phpmyadmin will response with 404 error.
  **Note:** The url shouldn't be "/phpmyadmin" because it's too easy for bots to find.
- **Protect the URL with "auth_basic"** and establish where the auth_basic_user_file is. This adds an extra layer of security (preventing brute force).
- **Protect the URL with IP whitelist**. You can uncomment and use allow/deny for IPs. If you have some specific IP, you can use it here. Also, you could make use of an SSH tunnel for extra security: (ssh user@domain -L 8000:localhost:443) and then allow only localhost IP through SSH tunell, like a VPN.

## Example:

Filename: mysite.conf

```nginx
    location /some_phpmyadmin_url {
#       allow YOUR_LOCALHOST_IP;
#       deny all;
        rewrite ^/some_phpmyadmin_url(/.*)$ $1 break;
        auth_basic "Please provide login infomation.";
        auth_basic_user_file /etc/nginx/passwords/sample;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $http_host;
        proxy_pass http://phpmyadmin:80;
        proxy_redirect off;
    }
```
