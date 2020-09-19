# Add postgres to the compose

## Usage:

Copy the postgresql container into the service section of the docker-compose.yml file.

- Update the .env file with the specified variables for POSTGRES (POSTGRES_DB, POSTGRES_PASSWORD, POSTGRES_NOT_ROOT_USERT and POSTGRES_NOT_ROOT_PASSWORD). They are the credentials for the database.
- Never expose ports: "80:80" because you make DB accessible outside the docker containers **(recommended)**.
- You can setup your own postgresql configuration modifying the file /conf/postgres/postgresql.conf and uncommenting the volume. You can use this docs: [docs](https://www.postgresql.org/docs/9.3/config-setting.html).
- Starting the database with content using an init.sql is a bad practice (model should come from the apps, not the SQL itself!).
- Use the not root user for your apps, it's less dangerous.
