# Beekeeper: A Slack Notifier for Docker Swarm

An embarassingly simple application which tails the Docker event logs, notifying a Slack webhook on non-zero container exits.

## Development & Testing

### .env

Create a .env file with the following contents. This file is git-ignored and won't be committed.

```ini
BEEKEEPER_WATCHERS="@your-username,#devops-alerts-test"
RSPEC_DOCKER=yes
SLACK_API_TOKEN="Get this from a Slack administrator"
```

### Build / Run / Test

This app depends on running in Swarm mode, so the build/test process is a little different than usual.

```sh
# Build per usual
docker compose build

# Deploy as a Swarm service (this is different)
docker stack deploy -c docker-compose.yml beekeeper

# Tail the logs
docker service logs -f beekeeper_app

# Run the tests or shell in
docker compose run --rm app rspec
docker compose run --rm app bash
```

## Production Considerations

The app requires access to `/var/run/docker.sock` in order to query the Docker API. The app could potentially use Docker's remote API but this is not currently implemented, and would be a bit painful to setup (requiring signed certificates). Also note that Docker events are node-specific, so use "global" mode to ensure an instance of the app is placed on each node.
