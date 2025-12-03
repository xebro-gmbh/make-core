#!/bin/bash
#--------------------------
# xebro GmbH - Compose Generator - 1.0.0
#--------------------------
# Generates compose.yaml files from compose.base.yaml + compose.<module>.yaml
# Dependencies are included only if the target module directory exists

set -e

# Source directory for modules
if [ -z "${XO_MODULES_DIR}" ]; then
    XO_MODULES_DIR="./docker"
fi

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "ERROR: yq is not installed!"
    echo "Please install yq v4+:"
    echo "  - macOS: brew install yq"
    echo "  - Linux: sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq"
    exit 1
fi

# Check yq version (needs v4+)
YQ_VERSION=$(yq --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
YQ_MAJOR=$(echo "$YQ_VERSION" | cut -d. -f1)
if [ "$YQ_MAJOR" -lt 4 ]; then
    echo "ERROR: yq version 4+ required (found version $YQ_VERSION)"
    exit 1
fi

# Function to check if module exists
module_exists() {
    [ -d "${XO_MODULES_DIR}/$1" ]
}

echo "Generating compose.yaml files..."

# For each module directory that has compose.base.yaml:
for module_dir in ${XO_MODULES_DIR}/*/; do
    module=$(basename "$module_dir")
    base_file="${module_dir}compose.base.yaml"

    if [ ! -f "$base_file" ]; then
        continue  # Skip if no base file
    fi

    echo "  Generating compose.yaml for ${module}..."

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
            echo "    - Merging $dep_module dependency"
            yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
                "${module_dir}compose.yaml" "$dep_file" > "${module_dir}compose.yaml.tmp"
            mv "${module_dir}compose.yaml.tmp" "${module_dir}compose.yaml"
        else
            echo "    - Skipping $dep_module (module not installed)"
        fi
    done
done

echo "Compose file generation complete!"
