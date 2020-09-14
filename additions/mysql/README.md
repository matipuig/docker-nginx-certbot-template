# Add mariadb/mysql to the compose

## Usage:

Copy the mysql/mariadb container into the service section of the docker-compose.yml file.

- Update the .env file with the specified variables for MYSQL (MYSQL_ROOW_PASSWORD, MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD). They are the credentials for the database.
- Never expose ports: "3306:3306" because you make DB accessible outside the docker containers **(recommended)**.
- You can setup your own mysql configuration modifying the file conf.d in conf/mysql/conf.d. You can use the docs: [docs](https://mariadb.com/kb/en/configuring-mariadb-with-option-files.).
- Starting the database with content using an init.sql is a bad practice, so we don't use it (model should come from the apps, not the SQL itself!).

**Note:** MYSQL/mariaDB with docker-compose it's a bit tricky. Maybe you will need to re run the docker container and volumes after starting it the first time.

## Getting logs:

If you want to use enable or disable logs in mariaDB/mysql you can use the scripts contained in /scripts.
Both of them will ask you a container name and the respective root password.

Usage:
```bash
. enable-logs.sh
. disable-logs.sh
```

Both scrips executes: docker exec mysql... and the respective mysql commands.

