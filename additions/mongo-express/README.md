# Add mongo-express to the compose

# **IMPORTANT**:

According to its official page:
This image is not secure and it's prepared to work with the root user. Only use it for development purposes. \*\* Do NOT use this in production.

## Usage:

Copy the mongo-express into the service section of the docker-compose.yml file.

- Modify the environment variable ME_CONFIG_SITE_BASEURL to the location the app will need. Vg: If it will be in "/some-place/me", this should be "/some-place/me/".
- Configure the reverse proxy in nginx.
- Do NOT expose its ports, and access it via reverse proxy.
- Add the container it will listen to in ME_CONFIG_MONGODB_SERVER and the user credentials in ADMIN_USERNAME and ADMIN_PASSWORD.
- Add the mongo container in the "depends_on" properties. Otherwise, it will crash trying to connect to a non started server.
- Add some temporal basic auth username and password if you want. You can delete those if you won't want one or you will do that via the reverse proxy. Why here and not in environment variable? Because you have to delete this quickly!

**Note**: You can add some security to this container, but, again, **use it only in development**.

## Example:

Filename: docker-compose.yml

```yaml
mongo-express:
  container_name: mongo-express
  image: mongo-express:latest
  environment:
    ME_CONFIG_MONGODB_SERVER: HERE_THE_MONGO_CONTAINER
    ME_CONFIG_MONGODB_ADMINUSERNAME: root
    ME_CONFIG_MONGODB_ADMINPASSWORD: ${MONGO_INITDB_ROOT_PASSWORD}
    ME_CONFIG_SITE_BASEURL: /some-place/me/
    ME_CONFIG_BASICAUTH_USERNAME: temp-username
    ME_CONFIG_BASICAUTH_PASSWORD: temp-password
  depends_on:
    - HERE_THE_MONGO_CONTAINER
  networks:
    - app-network
```

Filename: mysite.conf

```nginx
    location /some-place/me {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $http_host;
        proxy_pass http://mongo-express:8081;
        proxy_redirect off;
    }
```
