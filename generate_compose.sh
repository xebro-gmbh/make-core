#!/bin/bash
#--------------------------
# xebro GmbH - Compose Generator - 1.0.0
#--------------------------
# Generates compose.yaml files from compose.base.yaml + compose.<module>.yaml
# Dependencies are included only if the target module directory exists

set -euo pipefail

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    printf "${Red}ERROR:${Color_Off} yq is not installed!\n"
    printf "${Gray}Please install yq v4+:\n"
    printf "  - macOS: ${Cyan}brew install yq${Color_Off}\n"
    printf "  - Linux: ${Cyan}sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq${Color_Off}\n"
    exit 1
fi

# Check yq version (needs v4+)
YQ_VERSION=$(yq --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
YQ_MAJOR=$(echo "$YQ_VERSION" | cut -d. -f1)
if [ "$YQ_MAJOR" -lt 4 ]; then
    printf "${Red}ERROR:${Color_Off} yq version 4+ required (found version ${Cyan}%s${Color_Off})\n" "$YQ_VERSION"
    exit 1
fi

# Function to check if module exists
module_exists() {
    [ -d "${XO_MODULES_DIR}/$1" ]
}

printf "%b\n" "${Yellow}Generating compose.yaml files...${Color_Off}\n"

# For each module directory that has compose.base.yaml:
shopt -s nullglob
for module_dir in "${XO_MODULES_DIR}"/*/; do
    module=$(basename "$module_dir")
    base_file="${module_dir}compose.base.yaml"

    if [ ! -f "$base_file" ]; then
        continue  # Skip if no base file
    fi

    printf "${Gray}  Generating compose.yaml for ${Cyan}%s${Gray}...${Color_Off}\n" "$module"

    # Start with base file
    cp "$base_file" "${module_dir}compose.yaml"

    # Merge additional files if target modules exist
    for dep_file in "${module_dir}"compose.*.yaml; do
        # Skip base file
        if [ "$dep_file" = "$base_file" ] || [ "$dep_file" = "${module_dir}compose.yaml" ]; then
            continue
        fi

        # Extract module name from filename (compose.postgres.yaml -> postgres)
        dep_module=$(basename "$dep_file" .yaml | sed 's/^compose\.//')

        if module_exists "$dep_module"; then
            printf "${Gray}    - Merging ${Cyan}%s${Gray} dependency${Color_Off}\n" "$dep_module"
            yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
                "${module_dir}compose.yaml" "$dep_file" > "${module_dir}compose.yaml.tmp"
            mv "${module_dir}compose.yaml.tmp" "${module_dir}compose.yaml"
        else
            printf "${Gray}    - Skipping ${Cyan}%s${Gray} (module not installed)${Color_Off}\n" "$dep_module"
        fi
    done
done

printf "\n${Gray}Compose file generation ${Yellow}complete!${Color_Off}\n"
