# Add Redis to the compose

## Usage:

Copy the redis container into the service section of the docker-compose.yml file.

- **Never expose redis port**: Redis is prepared to run in trusted environments with trusted clients. You should never expose redis ports. See docs: [Redis security](https://redis.io/topics/security)
- If you don't need redis to persist data, you can erase the "command" line (appendonly is the command that do the persistence).
- Also, you can delete the "volume", so redis won't persist information.
