# Beekeeper: A Slack Notifier for Docker Swarm

An embarassingly simple application which tails the Docker event logs, notifying a Slack webhook on non-zero container exits. The only configurable option is the SLACK_WEBHOOK_URL, which must be supplied as a Docker secret at `/run/secrets/SLACK_WEBHOOK_URL`. When developing locally, you can store that value in the file `./secrets/SLACK_WEBHOOK_URL`, which is not committed to the repo.

For obvious reasons, the app needs to mount the Docker socket to work. This app doesn't work with the remote API.

Also note that Docker events are node-specific. If running this in a multi-node Swarm, use the "global" mode to ensure a replica is placed on each node in the Swarm.

In a nutshell:

```sh
# Spin up some service to use for testing
docker service create \
    --name fail-test \
    --replicas=0 \
    alpine /bin/sh -c 'echo "fake log data" && false'

# Build and start the app
docker-compose up --build -d

# Scale up/down your failure service to trigger relevant events
docker service scale fail-test=0
docker service scale fail-test=1
```

Check Slack to verify that the notifications were posted.
