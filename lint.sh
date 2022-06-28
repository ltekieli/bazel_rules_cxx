#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

for script in "${SCRIPT_DIR}"/tools/apply-*.sh; do
    echo "Executing: ${script}"
    /bin/bash "${script}"
done
