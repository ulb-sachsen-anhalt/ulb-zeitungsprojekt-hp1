#!/bin/bash

set -eu

PROJECT_DIR=$(pwd)
TESSTRAIN_DIR=tesstrain
TESSERACT_DATA=/usr/share/tesseract-ocr/4.00/tessdata

NEW_MODEL=$1
DATA_DIR=$2
START_MODEL=$3
TRAIN_MAX_ITERATIONS=$4


# ensure python env for tesstrain
[ -d ./venv ] || python3 -m venv venv

# shellcheck disable=SC1091
source ./venv/bin/activate
pip3 install --upgrade pip
pip install -r tesstrain/requirements.txt


if [ -z "${START_MODEL}" ]
then
    START_MODEL=frk
fi
if [ -z "${TRAIN_MAX_ITERATIONS}" ]
then 
    TRAIN_MAX_ITERATIONS=10000
fi

echo "[INFO] start new training with '${*}' at $(date) (Model: ${START_MODEL}, Iterations: ${TRAIN_MAX_ITERATIONS})"

cd ${TESSTRAIN_DIR}
make training MODEL_NAME="${NEW_MODEL}" \
    TESSDATA=${TESSERACT_DATA} \
    GROUND_TRUTH_DIR="${DATA_DIR}" \
    START_MODEL=${START_MODEL} \
    MAX_ITERATIONS=${TRAIN_MAX_ITERATIONS} \
    OUTPUT_DIR="${PROJECT_DIR}"/${TESSTRAIN_DIR}/data/"${NEW_MODEL}"

cd "$PROJECT_DIR"

NEW_MODEL_TESSTRAIN_PATH=${TESSTRAIN_DIR}/data/${NEW_MODEL}.traineddata
if [ ! -f "${NEW_MODEL_TESSTRAIN_PATH}" ]
then
    echo -e "
        [ERROR] missing resulting model '${NEW_MODEL}' at '${NEW_MODEL_TESSTRAIN_PATH}'!
    "
    exit 1
fi

echo "[INFO] training finished at $(date)"

# wait for model file being flushed to disc
sleep 10s

# store new model at cached place
mv "${NEW_MODEL_TESSTRAIN_PATH}" model/

# clear training tmp data
rm -rf ${TESSTRAIN_DIR}/data/**
