# xebro dev-setup

This is the main repository for the dev-setup make bundles. Every other folder inside `docker/` depends on this core and exposes its targets by letting the core `Makefile` include their definitions. The goal is to have a tiny, reproducible entrypoint that works for any proof-of-concept or small product without maintaining a bespoke CLI.

## Core Principles

- **Makefile as API** – `main_file` is copied or symlinked to your project root and becomes the only command surface (`make install`, `make start`, etc.).
- **Convention over scripting** – Targets rely on `.env`/`.env.local` plus helper files in `docker/etc` so you do not need wrapper scripts or ad-hoc shell glue.
- **Composable bundles** – Any folder in `docker/` that ships a `Makefile` and `compose.yaml` is auto-discovered. Bundles can depend on each other (e.g., PHP expects Postgres and LocalStack) but all of them point back to this core.
- **Self-documenting** – `make help` prints the merged target list so you can explore available commands without digging through files.

## Installation

1. Add the core as a git submodule or copy it into `docker/core`:
   ```bash
   mkdir -p docker
   git clone https://github.com/xebro-gmbh/make-core.git docker/core
   ```
   or as a git submodule

   ```bash
   git submodule add https://github.com/xebro-gmbh/make-core.git docker/core
   ```
   
2. Make the root `Makefile` point to the `main_file` (symlink preferred, copy as fallback for Windows/WSL2):
   ```bash
   ln -sf docker/core/main_file Makefile
   # on Windows/WSL2 if symlinks are unavailable:
   cp docker/core/main_file Makefile
   ```
3. Run the standard bootstrap sequence whenever you start a fresh checkout:
   ```bash
   make install   # ensure env vars and helper files exist
   make init      # install app dependencies, run migrations, seed data
   make start     # start docker-compose services from all enabled bundles
   ```

## QuickStart: Web Developer Environment

This QuickStart tutorial shows you how to set up a complete web development environment with **PHP (Symfony)**, **Node.js (React/Vue)**, **PostgreSQL**, and **Mailcatcher**.

### Prerequisites

- Docker and Docker Compose installed
- Git installed
- A new or existing project repository

### Step 1: Set up Core and Modules

Create the directory structure and install the required bundle modules:

```bash
# Create project directory (if new)
mkdir my-webapp && cd my-webapp

# initialize git (if not already)
git init

# Install Core Bundle
mkdir -p docker
git submodule add https://github.com/xebro-gmbh/make-core.git docker/core

# Link Makefile
ln -sf docker/core/main_file Makefile

# then use the existing make commands to add more submodules
make add.php
make add.node
make add.postgres

# when you already have an existnig repository and need to kickstart your submodules, because someone added those to the project
git submodule update --init

# or to update all submodules to the current version
git submodule update --remote

```

### Step 2: Initialize Environment

Set your project name and initialize the environment (the Docker network will be created automatically):

```bash
# Set project name in .env (e.g. XO_PROJECT_NAME=my-webapp)
echo "XO_PROJECT_NAME=my-webapp" > .env
```

Run the installation and initialization steps:

```bash
# Create environment variables and configuration files
make install

# Install dependencies (Composer, npm), run database migrations
make init

# Start all services
make start
```

### Step 3: What's Available Now?

After a successful start, you have the following services:

| Service         | URL/Port                | Description                                            |
|-----------------|-------------------------|--------------------------------------------------------|
| **PHP**         | `http://localhost:80`   | PHP running with an apache2 webserver                  |
| **Node.js**     | `http://localhost:3000` | React/Vue development server with hot-reload           |
| **PostgreSQL**  | `localhost:5432`        | Database (User: `app`, Password: `app`, DB: `symfony`) |
| **Mailcatcher** | `http://localhost:1080` | Email web interface for testing emails                 |

### Step 4: Development Workflow

**Backend (PHP/Symfony):**
```bash
# Open shell in PHP container
make php.bash

# Execute Symfony console commands
make php.cmd cmd="cache:clear"

# Run database migrations
make php.migrate

# Load test data
make php.fixtures

# Run tests
make php.test

# Check code quality
make php.verify
```

**Frontend (Node.js):**
```bash
# Open shell in Node container
make node.bash

# Install/update npm packages
make node.init

# Build for production
make node.build

# Run tests
make node.run TARGET=test
```

**Database (PostgreSQL):**
```bash
# Open PostgreSQL console
make postgres.console

# Export database
make postgres.export

# Show logs
make postgres.logs
```

**Email Testing (Mailcatcher):**
```bash
# Open web interface
open http://localhost:1080

# SMTP server for your application: mailcatcher:1025 (inside Docker)
# or localhost:1025 (from host)
```

### Step 5: Stop Everything

```bash
# Stop all services
make stop

# Restart services
make restart
```

### Help and Available Commands

Show all available Make targets:
```bash
make help
```

### Common Issues

**Services won't start:**
- Check if Docker network exists: `docker network ls`
- Check if ports are already in use: `lsof -i :80` / `lsof -i :3000`

**Database connection failed:**
- Wait until PostgreSQL is ready: `make postgres.logs`
- Check `.env` for correct `DATABASE_URL`

**Node modules not found:**
- Run `make node.init` to install npm packages

## Customisation Hooks

Adding project-specific commands is done through plain Makefiles:

1. Create `./bin/Makefile` (relative to your project root).
2. Define your custom targets and prepend them to existing ones if you need hooks.

```make
custom.test:
	echo "test"

install: custom.test
```

Because Make uses prerequisites you never overwrite core targets: you simply chain your custom ones in front of `install`, `start`, etc.

## Discovering Commands

`make help` aggregates the descriptions from every included bundle (core plus `docker/php`, `docker/node`, …). Use it whenever you add a new component to confirm the exported targets.

## Related Bundles

Most common bundles are already checked into this repository (`docker/php`, `docker/node`, `docker/postgres`, `docker/localstack`, `docker/mailcatcher`, `docker/etc`). You can also import other public bundles (for example `make-docker`, `make-traefik`, or any bundle you create) as long as their `Makefile` follows the same conventions—drop them under `docker/<name>` and the core will wire them in automatically.

## Compose File Generation

This system uses modular compose files that are dynamically merged based on installed modules:

- **`compose.base.yaml`** - Core service definition without optional dependencies
- **`compose.<module>.yaml`** - Adds `depends_on` for a specific module
- **`compose.yaml`** - Generated file (gitignored)

### How It Works

When you run `make install` or `make compose.generate`, the system:
1. Scans each module directory for `compose.base.yaml`
2. Checks which optional dependency modules are installed
3. Merges relevant `compose.<module>.yaml` files using `yq`
4. Generates the final `compose.yaml`

### Example: PHP Module

```
docker/php/
  ├── compose.base.yaml        # PHP service without dependencies
  ├── compose.postgres.yaml    # Adds postgres dependency
  ├── compose.localstack.yaml  # Adds localstack dependency
  └── compose.yaml             # Generated (merged result)
```

If both postgres and localstack modules are installed, the PHP service will depend on both. If only postgres is installed, PHP will only depend on postgres.

### Manual Regeneration

To regenerate compose files manually:
```bash
make compose.regenerate
```

### Requirements

The core bundle expects the following host tools to be available before running any `docker/` targets:

- `bash` (POSIX sh is not enough; the scripts rely on Bash 4+ features such as `mapfile`, `shopt`, and arrays).
- `make` for the entrypoint (`Makefile` in the repo root) plus every module target.
- `docker` (Engine and CLI) with Compose support (`docker compose` or a compatible `docker-compose` executable that can be referenced via `DOCKER_COMPOSE`).
- `yq v4+` for merging `compose.*.yaml` fragments into each module’s generated `compose.yaml`.
  - Install: `brew install yq` (macOS) or see [yq releases](https://github.com/mikefarah/yq/releases).
- `envsubst` (part of the GNU `gettext` package) because the configuration helpers expand variable placeholders when migrating `.env` entries.
  - macOS: `brew install gettext` (and `brew link --force gettext` if needed); Linux: `sudo apt install gettext-base` or equivalent.

## License

This make bundle is provided under the MIT License. See the [LICENSE](./LICENSE) file for details.

Copyright (c) 2025 xebro GmbH
