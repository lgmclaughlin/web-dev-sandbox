# Web Dev Sandbox
A secure, Docker-based sandbox for web development and CLI tooling. This template configures the Docker bridge network firewall with a separate firewall container, isolating the main dev container. Also supports mounting project folders and files from external sources via SSHFS.

The firewall setup was an adaptation of Anthropic's original version. I split the firewall setup out into a separate step with its own container. This allows firewall changes on the fly and avoids giving the main dev container access and NET_ADMIN / NET_RAW caps.

  ## Features
- Isolated, non-root development container
- Firewall container to restrict outbound network traffic to approved domains
- Commands for updating firewall whitelist
- Configurable script for mounting project files with SSHFS
- Persistent history and configuration via Docker volumes
- Set up for Claude out of the box, but adaptable for any CLI/web development tool
  
## Repo Structure

  ```
  web-dev-sandbox/
  ├── docker/
  │   ├── firewall/
  │   │   ├── docker-compose-firewall.yml # Firewall container
  │   │   ├── docker-firewall.sh          # Starts the firewall container
  │   │   ├── Dockerfile_firewall         # Firewall container image
  │   │   ├── firewall-apply.sh           # Firewall whitelist update helper script
  │   │   ├── firewall-init.sh            # Firewall init helper script
  │   │   ├── fw                          # Whitelist commands (ls, add, remove, update)
  │   │   └── whitelist.txt               # Whitelisted domains
  │   ├── docker-compose.yml              # Main container
  │   ├── docker.sh                       # Start the main container
  │   └── Dockerfile                      # Main container image
  ├── workspace/
  │   ├── .claude/
  │   │   └── settings.local.json         # Claude project settings
  │   ├── content
  │   └── .claudeignore                   # Claude ignore
  ├── mount.sh                            # SSHFS mount script
  └── README.md                           # This file
  ```

  ## Getting Started
  **Build and start the firewall container**
  ```
  ./docker/firewall/docker-setup.sh
  ```
  Runs the sandbox-firewall container. Both firewall-init.sh and firewall-apply.sh are copied into the container and run inside.
	- Applies network restrictions for all future containers on the Docker bridge network.

  **Modify the firewall whitelist**
  
  Manage the firewall whitelist with the ./fw script inside `docker/firewall`. It updates the firewall container's ipset using an atomic swap to ensure zero-downtime.
  
  Domains can be quickly added or removed with `./fw add <domain>` and `./fw remove <domain>`.
  
  Bulk domain changes can be made by modifying whitelist.txt and running `./fw update`.
  
  ```
  ./fw ls               Prints whitelist.txt
  ./fw add <domain>     Adds a domain to whitelist.txt and updates the firewall.
  ./fw remove <domain>  Removes a domain from whitelist.txt and updates the firewall.
  ./fw update           Updates the firewall based on the current whitelist.txt.
  ```

  **Mount project files**
  
  Modify the `CONTENT_PATH` variable in `mount.sh` to point to your remote file server.
  
  Once set, run the script. This will clean up any existing mounts before running `sshfs` with the given path and target folder.
  ```
  ./mount.sh
  ```

  **Start main container**
  
  ```
  ./docker/docker.sh
  ```
  If you’ve made changes to the Dockerfile or want to rebuild the image, use the `--build` argument:
	 ```
	 ./docker/docker.sh --build
	 ```

  **Attach to the container**
  
  ```
  docker exec -it web-dev-sandbox bash
  ```
  Your workspace will be mounted at `/workspace`. Dotfiles (e.g., `.claudeignore`) will be visible.

  ## Workspace
  
  History and configuration are persisted in Docker volumes:
  
	 `claude_history` → `/commandhistory`
	 `claude_config`  → `/home/node/.claude`

  ## Adapting for Other Tools
  
  Swap the CLI/tool installation in `Dockerfile` (e.g., replace `@anthropic-ai/claude-code`)
  
  Your firewall and container isolation remain intact
 
  Workspace and history/config volumes can be reused for any project

  ## Security Notes
  
- Firewall container handles network restrictions
- Root privileges are never exposed in main container
- Mounts are explicit; host system is protected
