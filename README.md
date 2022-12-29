# Getting Started with Hetzner Dedicated

Usually used for a beefy building machine or CI, [Hetzner offers](https://www.hetzner.com/dedicated-rootserver/matrix-ax)
the best price/performance.

Since these machines are bare metal, setting them up comes up with a cost - no more!

This setup uses a single command to bootstrap a machine and was tested using
[AX51-NVMe](https://www.hetzner.com/dedicated-rootserver/ax51-nvme),
but any machine with two SSDs should work.

It will set up a machine using raid1 and ext4 for the root filesystem.

## Rebooting the machine into rescue mode

1. Login to [Hetzner Robot](https://robot.hetzner.com/server)
2. Make sure to put your SSH key into https://robot.hetzner.com/key/index
3. Select the server you'd like to deploy
4. Click `Rescue` -> Make sure you have `linux` selected and your SSH key -> Click `Activate`
5. Click `Reset` -> Select `Execute an automatic hardware reset` -> Click `Send`

## Retrieving Cachix Deploy Agent token

1. Open [Cachix Deploy](https://app.cachix.org/deploy)
2. Select the account/organization in the menu
3. Create a new workspace
4. Click "Add an agent"
5. Pick a description and generate a token
6. Save the token as `CACHIX_AGENT_TOKEN=xxx` to `cachix-agent.token`

## Bootstrapping the machine

Clone this repo and make sure to set `sshPubKey` in `flake.nix` with your public SSH key.

From the email you received when the Hetzner machine was processed, take IP and replace it in `yourip`:

```shell-session
$ nix develop -c bootstrap-hetzner yourip myagent ./cachix-agent.token
```

Once the script finishes, your machine should come up in a few minutes and show up in your Cachix Deploy workspace.

In case anything goes wrong, you can order a remote console via the `Support` tab in [Hetzner Robot](https://robot.hetzner.com/server).

## Using CI for CD

