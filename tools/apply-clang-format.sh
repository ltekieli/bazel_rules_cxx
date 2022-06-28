#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

find "${SCRIPT_DIR}/../" \( -name "*.cpp" -or -name "*.h" \) -exec clang-format -style=file -i -fallback-style=none {} \;
