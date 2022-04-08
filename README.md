# Beekeeper: A Slack Notifier for Docker Swarm

An embarassingly simple application which tails the Docker event logs, notifying a Slack webhook on non-zero container exits.

## Configuration

### `SLACK_WEBHOOK_URL/SLACK_WEBHOOK_URL_FILE`

The application requires a Slack webhook URL in order to notify Slack. You can specify this directly via `ENV['SLACK_WEBHOOK_URL']`, in a file at `ENV['SLACK_WEBHOOK_URL_FILE']`, or specifically in the file `/run/secrets/SLACK_WEBHOOK_URL`.

In development, the easiest way is to commit it to a .env file at the root of the project. This file is git-ignored and won't be committed:

```ini
# .env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/…/…/…
```

### Docker Socket

The app listens for events directly on `/var/run/docker.sock`, so you must mount this. Docker events are node-specific, so if running this in a multi-node Swarm, use the "global" mode to ensure a replica is placed on each node in the Swarm.

## Testing

In a nutshell:

```sh
# Build and start the app
docker compose up --build -d

# Spin up some service to use for testing
docker service create \
    --name fail-test \
    --replicas=0 \
    --restart-condition=none \
    alpine /bin/sh -c 'echo "fake log data" && false'

# Scale up/down your failure service to trigger relevant events
docker service scale fail-test=0
docker service scale fail-test=1
```

Check Slack to verify that the notifications were posted.

There are also a number of rspec tests, but keep in mind that all Docker and Slack interactions are mocked, so they might not be the _most_ useful tests in the world. Execute tests using the `spec` rake task:

```ruby
docker compose run --rm app spec
```
