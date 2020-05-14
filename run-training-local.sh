#!/bin/bash

set -eu


# shellcheck disable=SC1091
source .env

time ./00-prepare.sh "${TRAIN_BASE_MODEL}" \
     "${TRAIN_DATA_PATH}"

time ./01-train.sh "${TRAIN_MODEL}" \
    "${TRAIN_DATA_PATH}" \
    "${TRAIN_BASE_MODEL}" \
    "${TRAIN_ITERATIONS}"
