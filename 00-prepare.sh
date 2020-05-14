#!/bin/bash

set -eu

#
# use local ImageMagick to convert images to proper format
#
convert_images() {
    local old_ext=bin.png
    local new_ext=tif

    i=0
    for f in ${1}
    do
        if [[ "$f" == *"${old_ext}" ]]
        then
            target=${f/%${old_ext}/${new_ext}}
            convert "$f" "$target"
            i=$((i+1))
        fi
    done
    echo "[INFO] converted '$i' files from '*.$old_ext' to '*.$new_ext'"
}

#
# check encoding: tesseract wants nothing but utf-8 
#
ensure_encoding_is_not() {
  list_files=()
  
  for txt_file in $1; do
    local file_info
    file_info=$(file "${txt_file}")
    if [[ ${file_info} =~ $2 ]]; then
        list_files+=("${txt_file}")
    fi
  done

  if [ ${#list_files[@]} -gt 0 ]; then 
    for entry in ${list_files[*]}; do
      echo "[ERROR] unwanted encoding '${2}' at '${entry}'!"
    done
    exit 1
  fi
}


#
# MAIN FLOW
#
# before actual training takes place, check existing model- and training data
#
# $1 => traineddata with label, i.e. "frk" for "frk.traineddata"
# $2 => label of new model (training result)
# $3 => path to training data
#
#
BASIS_MODEL=$1
TRAIN_PATH_DATA=$2


echo "[INFO] start training preparation in '$(pwd)' with args '${*}'"
# check: base model exists on training host
echo "[INFO] precheck: is model '${BASIS_MODEL}' available?"
EXISTING_TESSERACT_MODELS=$(tesseract --list-langs)
MODEL_EXISTS=$(echo "${EXISTING_TESSERACT_MODELS}" | grep "${BASIS_MODEL}")
if [ -z "${MODEL_EXISTS}" ]
then
    echo -e "
        [ERROR] missing model '${BASIS_MODEL}', abort pipeline!
    "
    exit 1
fi


# check: use proper model fpr training (not optimized version)
echo "[INFO] tesseract model '${BASIS_MODEL}': available, check model fits for training"
SIZE=$(stat --format=%s /usr/share/tesseract-ocr/4.00/tessdata/frk.traineddata)
EXPECTED_SIZE=12000000
if [[ ${SIZE} -lt ${EXPECTED_SIZE} ]]
then
    echo -e "
        [ERROR] Unexpected size '${SIZE} for model 'frk': wrong base-model, abort pipeline!
    "
    exit 1
fi


# check: traindata path valid?
if [ ! -d "${TRAIN_PATH_DATA}" ]
then
    echo -e "
        [ERROR] invalid training data path '${TRAIN_PATH_DATA}', abort pipeline!
    "
    exit 1
fi


# check: state of tesstrain submodule ok
TESSTRAIN_SUBMODULE=tesstrain
echo "[INFO] precheck: is '${TESSTRAIN_SUBMODULE}' up-to-date?"
if [ ! -d "${TESSTRAIN_SUBMODULE}" ]
then
    echo -e "
        [ERROR] missing '${TESSTRAIN_SUBMODULE}', abort pipeline!
    "
    exit 1
fi
echo "[INFO] clear tesstrain/data"
rm -rf ${TESSTRAIN_SUBMODULE}/data/**
echo "[INFO] fetching latest changes of '${TESSTRAIN_SUBMODULE}'"
git submodule update --remote ${TESSTRAIN_SUBMODULE}


# check: image format is png
N_PNG=$(find "${TRAIN_PATH_DATA}" -name "*bin.png" | wc -l)
if [ "$N_PNG" != "0" ]
then
    echo "[WARN] detected '${N_PNG}' *bin.png-files from ocrd-segmentation, convert them to *.tif-files"
    convert_images "${TRAIN_PATH_DATA}"
fi


# check: number gt text-files matches number gt images-files (tif)
N_TIF=$(find "${TRAIN_PATH_DATA}" -name "*.tif" | wc -l)
N_TXT=$(find "${TRAIN_PATH_DATA}" -name "*.gt.txt" | wc -l)
if [[ $N_TIF != "$N_TXT" ]]
then
    echo -e "
        [ERROR] detected missmatch: '${N_TIF}'(tif) != '${N_TXT}'(txt), abort pipeline!
    "
    exit 1
else
    echo "[INFO] Match: '${N_TIF}'(tif) == '${N_TXT}'(txt)"
fi


# check: each image has matching gt-text
for img_file_path in "${TRAIN_PATH_DATA}"/*.tif
do
    img_path_file_name=${img_file_path/%.tif/}
    txt_file_path=${img_path_file_name}.gt.txt
    if [ ! -r "${txt_file_path}" ]
    then
        echo -e "
            [ERROR] missing txt-file '${txt_file_path}' for image data '${img_file_path}'
        "
        exit 1
    fi
done


# check: encoding of training gt-files *NOT* UTF-16, but UTF-8 or ASCII
echo "[INFO] inspect training data text encoding"
encodings=("UTF-16")
for enc in ${encodings[*]}; do
    ensure_encoding_is_not "${TRAIN_PATH_DATA}/*.gt.txt" "$enc"
done
#ensure_encoding_is_not "${TRAIN_PATH_DATA}/*.gt.txt" "ASCII"
echo "[INFO] inspect training data text encoding: no 'UTF-16' detected"


# prepare: remove training artifacts
echo "[INFO] remove preceeding training artifacs from ${TRAIN_PATH_DATA}"
find "${TRAIN_PATH_DATA}" -name "*.box" -exec rm -f {} \;
find "${TRAIN_PATH_DATA}" -name "*.lstmf" -exec rm -f {} \; 
