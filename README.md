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

## Setting up Cachix 

1. Open [Cachix](https://app.cachix.org/) 
2. If you're part of a team, click `Select an account` and click `Create an organization`.
3. Click `Caches` in the top of the menu and create a new binary cache.
1. Open [Cachix Deploy](https://app.cachix.org/deploy)
2. Select the account/organization in the menu
3. Create a new workspace by selecting the previously created binary cache.
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

## Using Actions for CD

Your machine is running a plain NixOS configuration.

To deploy any changes from `main` branch you'll need to configure a few things in ``.github/workflows/deploy.yml`:

- `myagent`: if you picked a different agent/hostname, change it here
- `CACHE_NAME`: change `mycustomcache` into the name of the cache you created.
- `CACHIX_AUTH_TOKEN`: in [Cachix](https://app.cachix.org/), find your cache via settings and create a write auth token. Go to your git repository, click `Settings`, click `Secrets`, click `Actions` and add it as a repository setting.
- `CACHIX_ACTIVATE_TOKEN` in [Cachix Deploy](https://app.cachix.org/deploy), click on your newly created workspace and click "Start a deployment" to generate an token. Go to your git repository, click `Settings`, click `Secrets`, click `Actions` and add it as a repository setting.
