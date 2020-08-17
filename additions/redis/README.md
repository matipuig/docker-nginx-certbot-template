# Add Redis to the compose

## Usage:

Copy the redis container into the service section of the docker-compose.yml file.

- If you don't need redis to persist data, you can erase the "command" line (appendonly is the command that do the persistence).
- Also, you can delete the "volume", so redis won't persist information.
- Never expose port 6379 (redis for docker don't use password by default).
- Redis is meant for cache, session handling, pub/sub systems, and that kind of purposes. So please, don't make unsafe things...
