# Beekeeper: A Monitoring System for Docker Swarm

Beekeeper integrates API-based Docker Swarm monitoring with Slack notifications.

## Development & Testing

### .env

Scaffold a `.env` file from the included `.env.example`. See that file for details on the required environment variables.

```sh
cp .env.example .env
```

### Build / Run / Test

Beekeeper operates in Docker Swarm mode, so contrary to our other apps you'll need to setup two stacks:
1. The standard Compose-based stack with which you'll run tests.
2. A Docker Swarm "stack" containing testing-related services that behave in particular, planned ways (e.g. exiting a certain way).

```sh
# Build the image
docker compose build

# Deploy services used for testing
docker stack deploy -c beekeeper.yml beekeeper

# Run the tests or shell in
docker compose run --rm app rspec
docker compose run --rm app bash
```

## Production Considerations

The app requires access to `/var/run/docker.sock` in order to query the Docker API. The app could potentially use Docker's remote API but this is not currently implemented, and would be a bit painful to setup (requiring signed certificates). Also note that Docker events are node-specific, so use "global" mode to ensure an instance of the app is placed on each node.
