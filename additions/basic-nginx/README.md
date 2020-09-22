# Add basic-nginx to the compose.

This nginx image is very basic. If you want to use nginx for production, use the nginx-certbot option.
This image it's just for testing purposes, mainly if you won't use SSL (like in your localhost).

## Usage:

Copy the add-to-docker-compose file content in the docker-compose file (if you have another nginx image, like nginx-certbot, remove it).
Make it listen to 80 and 443 ports with TCP.
Then:

1. Configure nginx file in /conf/basic-nginx/conf.d. You can use the docs: [Nginx](https://nginx.org/en/docs/) and [DigitalOcean doc](https://www.digitalocean.com/community/tutorials/understanding-nginx-server-and-location-block-selection-algorithms).
1. You can pass certs to the image in the /certs file. This way, you can use SSL in nginx conf.
1. You can protect nginx and add security, but use the nginx-certbot image for that instead.
1. Add all the applications in the "depends_on" parameter. Othwerise, nginx will crash because it's trying to connect to a non-existent server.
