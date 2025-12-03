#--------------------------
# xebro GmbH - Make Core - 1.0.3
#--------------------------
.PHONY: .dockerignore docker.build docker.init

CORE_DIR := $(patsubst $(XO_ROOT_DIR)/%,./%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
CORE := $(notdir $(patsubst %/,%,$(CORE_DIR)))

## from https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
-include $(CORE_DIR)colors.mk

# ensure each line from $2 is present in $1, appending missing lines in order
define ensure_lines
	@${CORE_DIR}ensure_helpers.sh ensure_lines "$(1)" "$(2)"
endef

define ensure_file
	@set -e; \
	FILENAME=$(notdir $(1)); \
	printf "%b\n" "${Gray}Copy file ${Cyan}${2}/$$FILENAME ${Color_Off}"; \
	[[ -f "$(2)/$$FILENAME" ]] || { \
		cp "$(1)" "$(2)/$$FILENAME"; \
	}
endef

# ensure each env var definition from $2 exists in $1 after envsubst substitution; pass "force" as $3 to replace mismatched values
define ensure_env_vars
	@${CORE_DIR}ensure_helpers.sh ensure_env_vars "$(1)" "$(2)" "$(3)"
endef

define add_help
	@A="$2"; LINE="___________________________________________________________________" ; \
	printf "\33[33m%s\e[30m\e[43m%s\e[0m\33[33m%s" "___" " $$A " "$${LINE:$${#A}}"
	@echo ""
	@echo ""
	@awk -F ':|##' '/^[a-zA-Z\.-_0-9]+:.*##/ {\
	printf "\033[36m%-30s\033[0m %s\n", $$1, $$NF \
	}' $1 | sort
	@echo ""
endef

define headline
	@echo ""
	@echo -e "${Yellow}___${Black}${On_Yellow} ${1} ${Color_Off}${Yellow}_________________________${Color_Off}"
endef

define target_name
	@echo ""
	@echo -e "\n\n${Gray}____________________________ ${1} ${Color_Off}\n"
endef

core.install: ## Add all required entries to the .gitignore
	@mkdir -p ${XO_CONFIG_DIR}
	$(call headline,"Installing Core")
	$(call ensure_lines,.gitignore,${CORE_DIR}config/.gitignore)
	$(call ensure_env_vars,.env,${CORE_DIR}config/.env)
	@touch -- .env.local
	$(call ensure_file,${CORE_DIR}config/config.env,${XO_CONFIG_DIR})

# @see https://docs.docker.com/compose/environment-variables/envvars/
export COMPOSE_PROJECT_NAME=${XO_PROJECT_NAME}

docker.build:
	@${DOCKER_COMPOSE} build --build-arg USER_ID=$$(id -u) --build-arg GROUP_ID=$$(id -g) --build-arg UNAME=$$(whoami) --no-cache

docker.logs: ## show logs for all container
	@${DOCKER_COMPOSE} logs -f

docker.up: docker.network ## Start all docker container for development
	@${DOCKER_COMPOSE} up -d

docker.stop: ## Stop all docker container for development
	@${DOCKER_COMPOSE} stop --remove-orphans

docker.down: ## Stop all docker container for development
	@${DOCKER_COMPOSE} down --remove-orphans

docker.clean: ## Remove all docker Container and clean up System
	@${DOCKER_COMPOSE} down --remove-orphans
	@docker images | awk '$$2 == "<none>" {print $$3}' | xargs docker image rm -f

docker.kill: ## kill ALL docker container running on your Host
	@docker stop $$(docker ps -aq) | xargs docker rm

docker.pull: ## Update all docker container
	@${DOCKER_COMPOSE} pull

docker.cmd.cmd:
	@${DOCKER_COMPOSE} $$CMD

docker.network: ## create docker network
	@docker network inspect ${XO_PROJECT_NAME} >/dev/null 2>&1 || docker network create ${XO_PROJECT_NAME}

docker.config.dev: ## Show docker compose config
	@${DOCKER_COMPOSE} config

core.help:
	$(call add_help,${CORE_DIR}Makefile,"core")

docker.restart:
	@docker stop $$(docker ps -aq) | xargs docker rm
	@${DOCKER_COMPOSE} up -d

core.generate: ## Generate compose.yaml files from base + module files
	$(call target_name,$@)
	@bash ${XO_MODULES_DIR}/core/generate_compose.sh

core.docker-ignore:
	@touch .dockerignore
	$(call ensure_lines,"./config/.dockerignore","${CORE_DIR}.dockerignore")

core.debug:
	@$(call headline,"DEBUGGING Core")
	@printf "running debug for ${Yellow} xebro Makefile\n\n"
	@printf "${Purple}COMPONENT: ${Yellow} ${CORE}\n"
	@printf "${Purple}APP_ENV: ${Yellow} ${APP_ENV}\n"
	@printf "${Purple}DATABASE_URL: ${Yellow} ${DATABASE_URL}\n"
	@printf "${Purple}DOMAIN: ${Yellow} https://${DOMAIN}\n"
	@printf "${Purple}MERCURE_PUBLIC_URL: ${Yellow} ${MERCURE_PUBLIC_URL}\n"
	@printf "${Purple}MERCURE_URL: ${Yellow} ${MERCURE_URL}\n"
	@printf "${Purple}VERSION: ${Yellow} ${VERSION}\n"
	@printf "${Purple}XO_MODULES_DIR: ${Yellow} ${XO_MODULES_DIR}\n"
	@printf "${Purple}XO_PROJECT_NAME: ${Yellow} ${XO_PROJECT_NAME}\n"
	@printf "${Purple}XO_ROOT_DIR: ${Yellow} ${XO_ROOT_DIR}\n"

git.clean:
	git branch -r --merged main | grep -v main | sed 's/origin\///' | xargs git push origin -d
	git branch --merged main | grep -v production | grep -v main | xargs git branch -D

.dockerignore: core.docker-ignore
clean: git.clean docker.clean
debug: core.debug
help: core.help
init: docker.network
install: core.install core.docker-ignore
post_install: core.generate
logs: docker.logs
restart: docker.restart
start: docker.up
stop: docker.down
