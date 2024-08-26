#--------------------------
# xebro GmbH - Make Core - 0.0.2
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
	@${XEBRO_MODULES_DIR}/core/add_code_block.php $(1) $(2) $(3)
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
	$(call headline,"Installing Core")
	$(call add_config,.gitignore,${XEBRO_MODULES_DIR}/core/.gitignore)
	$(call add_config,.env,${XEBRO_MODULES_DIR}/core/.env)
	@touch -- .env.local

install: core.install

help: core.help


