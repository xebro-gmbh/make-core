# Docker Core

`docker/core` is the main repository for the struktur8 make bundles. Every other folder inside `docker/` depends on this core and exposes its targets by letting the core `Makefile` include their definitions. The goal is to have a tiny, reproducible entrypoint that works for any proof-of-concept or small product without maintaining a bespoke CLI.

## Core Principles

- **Makefile as API** – `main_file` is copied or symlinked to your project root and becomes the only command surface (`make install`, `make start`, etc.).
- **Convention over scripting** – Targets rely on `.env`/`.env.local` plus helper files in `docker/etc` so you do not need wrapper scripts or ad-hoc shell glue.
- **Composable bundles** – Any folder in `docker/` that ships a `Makefile` and `compose.yaml` is auto-discovered. Bundles can depend on each other (e.g., PHP expects Postgres and LocalStack) but all of them point back to this core.
- **Self-documenting** – `make help` prints the merged target list so you can explore available commands without digging through files.

## Installation

1. Keep the core as a git submodule or copy it into `docker/core`:
   ```bash
   mkdir -p docker
   git clone https://github.com/xebro-gmbh/make-core.git docker/core
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

These steps are idempotent; you can re-run them after pulling new code.

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

## License

This make bundle is provided under the MIT License. See the [LICENSE](./LICENSE) file for details.

Copyright (c) 2025 xebro GmbH
