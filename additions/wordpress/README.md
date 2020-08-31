# Add wordpress to compose

## Usage:

Be careful configuring nginx with wordpress. It can be tricky because of the way in which wordpress works.

### Docker-compose

- Do not expose any port (it's easier to configure security with nginx as a reverse proxy than in wordpress itself).
- Edit the environment variables to use MYSQL/MariaDB with Wordpress (in DB_HOST you should have a mysql container). Have a database user different to other apps users (if someone steals information, will have only your wordpress credentials).
- Edit the environment variable WORDPRESS_LOCATION. It's the subdirectory where you will put wordpress. Vg: domain.com/this_url or domain.com/this_other_url
  The wordpress location should be "/this_url" or "/this_other_url". If you wont' have a subdir, just use "/".
  ```yml
        WORDPRESS_CONFIG_EXTRA: |
        define('WP_HOME','https://your-domain.com${WORDPRESS_LOCATION}');
        define('WP_SITEURL','https://your-domain.com${WORDPRESS_LOCATION}');
  ```
  ...

```yml
volumes:
  - wordpress:/var/www/html${WORDPRESS_LOCATION}
  - ./conf/wordpress/themes:/var/www/html${WORDPRESS_LOCATION}/wp-content/themes/
  - ./conf/wordpress/plugins:/var/www/html${WORDPRESS_LOCATION}/wp-content/plugins/
working_dir: /var/www/html${WORDPRESS_LOCATION}
```

This might seem complicated, but it's related to how apache works with wordpress. If you redirect in nginx from /this_url to a container directly, you will have wrong redirects in /wp-admin, /wp-login, etc. If you have the wordpress in a subsite like "/wordpress", you should also have the content in /var/www/html/wordpress. Otherwise, you will always be redirected to domain.com/wp-admin instead of domain.com/wordpress/wp-admin.

**Note**: Pay attention to volumes, where you can have "//" as volumes, this could be a path error.

- Install different themes and plugins in the dirs conf/wordpress/themes and /plugins.
- Configure WP_HOME and WP_SITEURL urls in WORDPRESS_CONFIG_EXTRA. This is necessary in order to have wordpress correctly redirected.
- You can also edit WORDPRESS_CONFIG_EXTRA. All this variables will be set to wp-config.php THE FIRST time the volume is created. Source on wp-config.php: [docs](https://www.wpbeginner.com/beginners-guide/how-to-edit-wp-config-php-file-in-wordpress/#:~:text=Simply%20right%20click%20on%20the,like%20Notepad%20or%20Text%20Edit).
- Also, you should have the function setting \$\_SERVER['HTTPS'], because, otherwise, you would be in an infinite loop redirecting from port 80 to 443. Source:
  [https://wordpress.org/support/article/administration-over-ssl/#using-a-reverse-proxy](https://wordpress.org/support/article/administration-over-ssl/#using-a-reverse-proxy)

```yml
WORDPRESS_CONFIG_EXTRA: |
  define('WP_HOME','https://your-domain.com${WORDPRESS_LOCATION}');
  define('WP_SITEURL','https://your-domain.com${WORDPRESS_LOCATION}');
  define('SCRIPT_DEBUG', true );
  define('WP_DEBUG_LOG', true );
  define('WP_DEBUG_DISPLAY', true );
  define('FORCE_SSL_ADMIN', true);
  define('FS_METHOD','direct');
  $$_SERVER['HTTPS'] = '1';
  if (isset($$_SERVER['HTTP_X_FORWARDED_HOST'])) {
      $$_SERVER['HTTP_HOST'] = $$_SERVER['HTTP_X_FORWARDED_HOST'];
  }
```

### CONFIGURE NGINX.

- If you set wordpress in a subdomain, add "/LOCATION/" in url and in the proxy_pass. If you don't, just use "/". This is because what we mentioned above, in order to prevent /wp-admin always redirecting to the wrong URL. In the filesystem, the location would be /var/www/html/LOCATION, so, you should proxypass to http://container/LOCATION.

```nginx
    location /LOCATION/ {
        proxy_pass          http://wordpress/LOCATION/;
        proxy_redirect      http://$host https://$host;
        proxy_set_header    X-Forwarded-Host $http_host;
        proxy_set_header    X-Real-IP $remote_addr;
        proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto https;
        proxy_set_header    Host $host;
    }
```

- Do not forget to proxy_redirect changing http to https (or, otherwise, you will have another infinite loop from 80 to 443).
- The other settings are in order to make nginx work as a reverse proxy correctly.
- In /wp-admin you should also add auth_basic in order to increase security.

```nginx
    location /LOCATION/wp-admin/ {
        auth_basic "Please provide login infomation.";
        auth_basic_user_file /etc/nginx/passwords/sample;
        proxy_pass          http://wordpress/LOCATION/wp-admin;
        proxy_redirect      http://$host https://$host;
        proxy_set_header    X-Forwarded-Host $http_host;
        proxy_set_header    X-Real-IP $remote_addr;
        proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto https;
        proxy_set_header    Host $host;
    }
```

### Other.

Wordpress original image can't send emails, so this is a modified version to allow sendmail function.
Docs on how to send mails with wordpress: https://github.com/docker-library/wordpress/issues/30#issuecomment-317511836

### WORDPRESS SECURITY.

Even if nginx is secure, you shouldn't rely only on it. Try to also use best practices on wordpress security.
