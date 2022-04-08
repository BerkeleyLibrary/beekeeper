# Beekeeper: A Slack Notifier for Docker Swarm

An embarassingly simple application which tails the Docker event logs, notifying a Slack webhook on non-zero container exits.

## Configuration

### Slack Webhook URL

Notifying Slack requires a webhook URL, which must be procured separately by a Slack administrator. Once you've got it, you can provide it to the application via:

1. The `SLACK_WEBHOOK_URL` environment variable, which should contain its literal string value.
2. The file specified by the `SLACK_WEBHOOK_URL_FILE` environment variable.
3. Specifically in the file `/run/secrets/SLACK_WEBHOOK_URL`.

The easiest way to set this up in development is to create a `./env` file at the root of the project and specify it there like so:

```ini
# .env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/…/…/…
```

This file is git-ignored and will not be committed.

### Docker Socket

The app requires access to `/var/run/docker.sock` in order to query the Docker API. The app could potentially use Docker's remote API but this is not currently implemented, and would be a bit painful to setup (requiring signed certificates). Also note that Docker events are node-specific, so use "global" mode to ensure an instance of the app is placed on each node.

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

Check Slack to verify that the notifications were posted to the channel(s) configured for your webhook.

There are also a number of rspec tests, but keep in mind that all Docker and Slack interactions are mocked, so they might not be the most useful tests in the world. Execute tests using the `spec` rake task:

```ruby
docker compose run --rm app spec
```

You can also boot into a Ruby console using the `console|c` task a la Rails:

```ruby
docker compose run --rm app c
```
