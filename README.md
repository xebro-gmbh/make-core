xebro Make bundle
====

Makefiles organized in bundles (subfolders) for an easy development environment setup and handling.

I've seen full-fledged development environments written in Python, Php etc... that need to be maintained
by a developer in full time.

Most of my projects are at a POC level or small (maybe micro) sized website, where I want to test something.
Now the `xebro Makefiles` come in handy.

Those are only Makefiles, organized in Subfolder, with the least possible amount of a programming language.


## Goals
I want to make it easy to set up a development environment, and to run the project.
I forget always about all the steps to set up a project, and I want to focus on the project itself.

So I started to gather all required steps in a makefile and now here we are.


## Install
Install the core modes as git submodule, and then just symlink the `main_file` to the project root directory as `Makefile`.
All Windows users need to copy the file instead of creating a symlink, because symlinks in windows are not possible.

```bash
mkdir -p docker
git clone https://github.com/xebro-gmbh/make-core.git docker/core
ln -sf docker/core/main_file Makefile

```

On windows, but keep in mind that you will need to update this makefile manually

```bash
cp docker/core/main_file Makefile
```

### Quick start
Install all environment variables (written to .env or .gitiognore), the targets can be run multiple times.

```bash
make install
make init
make start
```

`install` will add all environment variables to the `.env` file, and `init` will install all dependencies.
`start` will start all docker containers.

## Bundles
    https://github.com/xebro-gmbh/make-docker
    https://github.com/xebro-gmbh/make-mariadb
    https://github.com/xebro-gmbh/make-php-fpm
    https://github.com/xebro-gmbh/make-traefik
    https://github.com/xebro-gmbh/make-node

Any many more


### Help

When you need more information about all possible commands, you can run:

```bash
make help
```

This will output all available commands.


### Custom bundles

You want to add your own Makefile targets, then just create a Makefile in the folder `./bin` and 
this file is included by default.

Add to the Makefile in `./bin/Makefile`

```Makefile
custom.test:
	echo "test"

install: custom.test
```

and now your command will output the string "test", when you run `make install`.


### Makefile Hooks

You can use "hooks" to execute your own commands, when the project starts or stops, etc...

Makefile targets cannot be overwritten, but you can add your own targets as prerequisites.
So you can add your own hooks without touching the original Makefile.

```Makefile
my.target:
	echo "my target"
	
install: my.target
```

This will output the string "my target", when you run `make install` from the project root.

### Available targets
```Makefile
start: ## start development environment
stop: ## stop development environment
install: ## init project and install all dependencies
build:
help:
```
