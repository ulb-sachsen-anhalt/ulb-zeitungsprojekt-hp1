#!/bin/bash

set -ex

TRAIN_BASE_MODEL=gt4hist_5000k
TRAIN_ULB_MODEL=your_trained_model
TRAIN_MAX_ITERATIONS=20000
ABS_PATH=$(realpath "$0")
PROJECT_DIR=$(dirname "${ABS_PATH}")
TRAIN_PATH_DATA=${PROJECT_DIR}/data

./00-prepare.sh ${TRAIN_BASE_MODEL}\
     "${TRAIN_PATH_DATA}"

./01-train.sh ${TRAIN_ULB_MODEL} \
    "${TRAIN_PATH_DATA}" \
    ${TRAIN_BASE_MODEL} \
    ${TRAIN_MAX_ITERATIONS} 0.90
