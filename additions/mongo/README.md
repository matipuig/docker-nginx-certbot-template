# Add mongo to the compose

## Usage:

Copy the mongo container into the service section of the docker-compose.yml file.

- Erase "ports: 27017:27017" to make mongo not accesible from outside the compose **(recommended)**. DO NOT expose mongoDB ports, or your database will be accesible from outside the network.
- Set the environment variables for the database (MONGO_INITDB_DATABASE), root user (MONGO_INITDB_ROOT_PASSWORD) user and the user your app will use (MONGO_USERNAME and MONGO_PASSWORD).

**Note**: Do **NOT** use the root user for the database in your apps. Use the other user with less privileges.
