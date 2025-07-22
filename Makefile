#--------------------------
# xebro GmbH - Make Core - 1.0.2
#--------------------------
.PHONY: .dockerignore

## from https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
## thx
# Reset
Color_Off=\033[0m

# Regular Colors
Black=\033[0;30m
Gray=\033[1;30m
Red=\033[0;31m
Green=\033[0;32m
Yellow=\033[0;33m
Blue=\033[0;34m
Purple=\033[0;35m
Cyan=\033[0;36m
White=\033[0;37m

# Underline
UBlack=\033[4;30m
URed=\033[4;31m
UGreen=\033[4;32m
UYellow=\033[4;33m
UBlue=\033[4;34m
UPurple=\033[4;35m
UCyan=\033[4;36m
UWhite=\033[4;37m

# Background
On_Black=\033[40m
On_Red=\033[41m
On_Green=\033[42m
On_Yellow=\033[43m
On_Blue=\033[44m
On_Purple=\033[45m
On_Cyan=\033[46m
On_White=\033[47m

define add_config
	@echo -e "${Gray}Adding config from ${Yellow}$2${Gray} to ${Yellow}$1${Color_Off}"
	@./${XO_MODULES_DIR}/core/add_code_block.php $(1) $(2) $(3)
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

core.install: ## Add all required entries to the .gitignore
	@mkdir -p ${XO_MODULES_DIR}
	$(call headline,"Installing Core")
	$(call add_config,.gitignore,${XO_MODULES_DIR}/core/.gitignore)
	$(call add_config,.env,${XO_MODULES_DIR}/core/.env)
	@touch -- .env.local

core.docker-ignore:
	@touch .dockerignore
	$(call add_config,".dockerignore","${XO_MODULES_DIR}/core/.dockerignore")

core.debug:
	@$(call headline,"DEBUGGING Core")
	@printf "running debug for ${Yellow} xebro Makefile\n\n"
	@printf "${Purple}APP_ENV: ${Yellow} ${APP_ENV}\n"
	@printf "${Purple}DATABASE_URL: ${Yellow} ${DATABASE_URL}\n"
	@printf "${Purple}DOMAIN: ${Yellow} https://${DOMAIN}\n"
	@printf "${Purple}MERCURE_PUBLIC_URL: ${Yellow} ${MERCURE_PUBLIC_URL}\n"
	@printf "${Purple}MERCURE_URL: ${Yellow} ${MERCURE_URL}\n"
	@printf "${Purple}VERSION: ${Yellow} ${VERSION}\n"
	@printf "${Purple}XO_MODULES_DIR: ${Yellow} ${XO_MODULES_DIR}\n"
	@printf "${Purple}XO_PROJECT_NAME: ${Yellow} ${XO_PROJECT_NAME}\n"
	@printf "${Purple}XO_ROOT_DIR: ${Yellow} ${XO_ROOT_DIR}\n"


install: core.install

git.clean:
	git branch -r --merged main | grep -v main | sed 's/origin\///' | xargs git push origin -d
	git branch --merged main | grep -v production | grep -v main | xargs git branch -D

debug: core.debug

clean: git.clean
.dockerignore: core.docker-ignore
install: core.docker-ignore
