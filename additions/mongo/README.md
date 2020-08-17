# Add mongo to the compose

## Usage:

Copy the mongo container into the service section of the docker-compose.yml file.

- Erase "ports: 27017:27017" to make mongo not accesible from outside the compose **(recommended)**.
- Add to the .env file the MONGO_INITDB_ROOT_USERNAME and MONGO_INITDB_ROOT_PASSWORD variables (are the credentials to access mongo).
- If you need, you can change the mongo configuration in the file /conf/mongo/mongod.conf.
- You have the [Docs for mongodb file configuration](https://docs.mongodb.com/manual/reference/configuration-options/)
