# Training Data Zeitungsdigitalisierung ULB

Data and workflow of the project "Zeitungsdigitalisierung Hauptphase I" at ULB Sachsen-Anhalt.

Includes [tesseract-ocr/tesstrain](https://github.com/tesseract-ocr/tesstrain) as submodule to do the actual tesseract model training via `lstmtraining`.

Actual training data sets are located in `data` - subfolder, organized in subfolders for each newspaper's PPN respectively.

## Installation

### Prerequisities

First of all, you need of course a tesseract installation, since tesstrain is like a middle-ware to run the actual training with tesseract itself. Please install tesseract from `ppa:alex-p/tesseract-ocr` or compile yourself. The training runs at ULB started with tesseract 4.1.1.

Next, we need a base model to start our training from.

* `frk`: <https://github.com/tesseract-ocr/tessdata_best/raw/master/frk.traineddata>
* `Fraktur`: <https://github.com/tesseract-ocr/tessdata_best/raw/master/script/Fraktur.traineddata>
* `GT4Hist`: <https://ub-backup.bib.uni-mannheim.de/~stweil/ocrd-train/data/Fraktur_5000000/Fraktur_5000000_0.466.traineddata>

Please note:  
_The language configuration files that can be installed from official ubuntu 18.04-Repository **do not** fit for training!_

Finally, clone this repository: `git clone --recursive git@github.com:ulb-sachsen-anhalt/ulb-zeitungsprojekt-hp1.git` and switch into the project root folder.

### Setup

In order to get the training process up and running, place an `.env`-file in the project root directory with the following configurations:

```shell
TRAIN_BASE_MODEL=<name-of-base-model, i.e. "frk">
TRAIN_ITERATIONS=<number-of-training-iterations>
TRAIN_MODEL=<name-of-resulting-model>
TRAIN_DATA_PATH=<absolute-path-of-folder-with-training-data>
```

These variables are being read by the training-scripts.  
Please note, that the base model configurations have to be placed in the tesseract `tessdata` configuration location, i.e. `/usr/share/tesseract-ocr/4.00/tessdata/` for tesseract 4.x.

The `TRAIN_DATA_PATH` must be an absolute local path. Feel free to use the ULB training datasets from the `data`-folder or use your own.

## Run Training

Execute `./run-training-local.sh`.
