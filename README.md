xebro Make bundle
====

Makefiles organized in bundles (subfolders) for an easy development environment setup and handling.

I've seen full fledged development environments written in Python, Php etc... which needs to be maintained
by a developer in full time.

Most of my project are at a POC level or small (maybe micro) sizes website, where I want to test something.
Now the `xebro Makefiles` come in handy.

Those are only Makefiles, organized in Subfolder, with the least possible amount of a programming language.


## Goals
* Readability is king, write more lines and ignore all fancy short notation stuff
* YAGNI, Don't overengineer your code. Don't fix problems you don't have
* Don't build wrapper for existing tools.
* KISS. Keep it super simple.


## Install
Install the core modes as git submodule, and then just symlink the `main_file` to the project root directory as `Makefile`.
All windows user need to copy the file instead of symlinking, because symlinking in windows is not possible.


```bash
mkdir -p docker
git clone https://github.com/xebro-gmbh/make-core.git docker/core
ln -sf docker/core/main_file Makefile
```

```bash
cp docker/core/main_file Makefile
```

### Quick  start
Install all environment variables (written to .env or .gitiognore), the targets can be run multiple times.

```bash
make install
make init
```

## Bundles



### Help

When you need more information about all possible commands you can run:

```bash
make help
```

This will ouput all available command.


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

You can use hooks to execute your own commands, when the project starts or stops, etc...

```Makefile
start: ## start development environment
stop: ## stop development environment
install: ## init project and install all dependencies
build:
help:
```
