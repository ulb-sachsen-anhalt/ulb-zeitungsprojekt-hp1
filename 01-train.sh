#!/bin/bash

set -eu

PROJECT_DIR=$(pwd)
TESSTRAIN_DIR=tesstrain
TESSERACT_DATA=/usr/share/tesseract-ocr/4.00/tessdata
LSTM_IMAGE=eval-tesseract
# LSTM_IMAGE_REF=a9682bb
LSTM_IMAGE_REF=4.1.1
#LSTM_IMAGE_REF=5.0.0-alpha-20210401
LSTM_CNT_NAME=tesseract5-lstmtrain 

# script args
# name of new model
NEW_MODEL=$1
# local path with training pairs (*.gt.txt + *.tif) reside
TRAIN_DATA_DIR=$2
# base model to start training from
TRAIN_FROM_MODEL=$3
# max number of iterations to go
# as long as target error rate is not reached
TRAIN_MAX_ITERATIONS=$4
# ration split data into train (=tesstrain defaul: 0.90) 
# reminder is used to test current model within iteration
RATIO_TRAIN=$5
# image consumption used by tesseract's lstmtrain
MAX_IMAGE_MB=12000


# ensure default settings
sanitize_params() {
    if [ -z "${TRAIN_FROM_MODEL}" ]; then
        TRAIN_FROM_MODEL=frk
    fi
    if [ -z "${TRAIN_MAX_ITERATIONS}" ]; then 
        TRAIN_MAX_ITERATIONS=10000
    fi
    if [ -z "${RATIO_TRAIN}" ]; then
        RATIO_TRAIN=0.90
    fi
}


# training using the Host-installed Tesseract Version
train_local() {
    time make training MODEL_NAME="${NEW_MODEL}" \
        TESSDATA=${TESSERACT_DATA} \
        START_MODEL="${TRAIN_FROM_MODEL}" \
        GROUND_TRUTH_DIR="${TRAIN_DATA_DIR}" \
        MAX_ITERATIONS="${TRAIN_MAX_ITERATIONS}" \
        DATA_DIR="${PROJECT_DIR}"/data \
        RATIO_TRAIN=${RATIO_TRAIN} \
        MAX_IMAGE_MB=${MAX_IMAGE_MB} \
        WORDLIST_FILE="${PROJECT_DIR}"/resources/hdz.sorted.wordlist \
        PUNC_FILE="${PROJECT_DIR}"/resources/hdz.punc \
        NUMBERS_FILE="${PROJECT_DIR}"/resources/hdz.numbers \
        -f tesstrain/Makefile

    # check trainined model output path
    NEW_MODEL_TESSTRAIN_PATH=data/${NEW_MODEL}.traineddata
    if [ ! -f "${NEW_MODEL_TESSTRAIN_PATH}" ]; then
        echo -e "[ERROR] missing resulting model '${NEW_MODEL}' at '${NEW_MODEL_TESSTRAIN_PATH}'!"
        exit 1
    fi
}


train_inside_container() {
    # clear latest run
    docker rm ${LSTM_CNT_NAME} || echo "[WARN] no previous '${LSTM_CNT_NAME}' found"

    # run
    docker run \
    --user "$(id -u)":"$(id -g)" \
    --name ${LSTM_CNT_NAME} \
    --mount type=bind,source="${TESSERACT_DATA}",target=/usr/local/share/tessdata \
    --mount type=bind,source="${TRAIN_DATA_DIR}",target=/traindata \
    --mount type=bind,source="${PROJECT_DIR}/tesstrain",target=/tesstrain \
    --mount type=bind,source="${PROJECT_DIR}/model",target=/model \
    --mount type=bind,source="${PROJECT_DIR}/data",target=/data \
    --workdir "/tesstrain" \
    "${LSTM_IMAGE}:${LSTM_IMAGE_REF}" \
    make training MODEL_NAME="${NEW_MODEL}" DATA_DIR=/data ${TESSERACT_DATA} START_MODEL="${TRAIN_FROM_MODEL}" GROUND_TRUTH_DIR=/traindata MAX_ITERATIONS="${TRAIN_MAX_ITERATIONS}" OUTPUT_DIR=/model/"${NEW_MODEL}"
    
    # check trained model output path
    NEW_MODEL_TESSTRAIN_PATH=${PROJECT_DIR}/model/${NEW_MODEL}.traineddata
    if [ ! -f "${NEW_MODEL_TESSTRAIN_PATH}" ]; then
        echo -e "[ERROR] missing resulting model '${NEW_MODEL}' at '${NEW_MODEL_TESSTRAIN_PATH}'!"
        exit 1
    fi
}

###########
# MAIN FLOW
###########
#
# ensure python env for tesstrain
[ -d ./venv ] || python3 -m venv venv
#
# shellcheck disable=SC1091
source ./venv/bin/activate
pip3 install -U pip
pip install -r tesstrain/requirements.txt
#
# take care of possible empty data
sanitize_params
#
# here we go again
echo "[INFO] start training with '${*}' at $(date) (Start Model: ${TRAIN_FROM_MODEL}, Iterations: ${TRAIN_MAX_ITERATIONS})"
#
# train local?
#train_local
#
# train with container?
#time train_inside_container
time train_local
#
# postprocessing
# check for trained model and store it in default model dir

echo "[INFO] training finished at $(date)"
# wait for model file being flushed to disc
sleep 7s
# store new model at cached place
mv "${NEW_MODEL_TESSTRAIN_PATH}" model/
# clear training tmp data
rm -rf ${TESSTRAIN_DIR}/data/**
