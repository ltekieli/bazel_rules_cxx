#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

buildifier -r "${SCRIPT_DIR}/../"
