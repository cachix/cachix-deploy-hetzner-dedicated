# Getting Started with Hetzner Dedicated

This setup was tested using [AX51-NVMe](https://www.hetzner.com/dedicated-rootserver/ax51-nvme),
but any machine with two SSDs should work.

It will set up a machine using raid1 and ext4 for the root filesystem.

## Rebooting the machine into rescue mode

1. Login to [Hetzner Robot](https://robot.hetzner.com/server)
2. Make sure to put your SSH key into https://robot.hetzner.com/key/index
3. Select the server you'd like to deploy
4. Click `Rescue` -> Make sure you have `linux` selected and your SSH key -> Click `Activate`
5. Click `Reset` -> Select `Execute an automatic hardware reset` -> Click `Send`

## Retrieving Cachix Deploy Agent token

1. https://app.cachix.org/deploy
2. Select the account/organization in the menu
3. Create a new workspace
4. Click "Add an agent"
5. Pick a description and generate a token
6. Save the token as `CACHIX_AGENT_TOKEN=xxx` to `cachix-agent.token`

## Bootstrapping the machine

From the email your received when the Hetzner machine was processed, take IP and replace it in `yourip`:

```shell-session
$ nix develop
$ cachix-deploy-bootstrap-hetzner yourip myagent ./cachix-agent.token
```

Once the script finishes, your machine should come up in a few minutes.

In case anything goes wrong, you can order a remote console via `Support` tab in Hetzner.

## Using CI for CD

