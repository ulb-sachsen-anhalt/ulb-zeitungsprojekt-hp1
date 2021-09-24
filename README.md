# Training Data Zeitungsdigitalisierung HP I

Data of the DFG-Project "Zeitungsdigitalisierung Hauptphase I" at University and States Library Saxony-Anhalt (2019-2021).

In the progress of the project, there were 550.000 newspaper pages ocr-ed, at first with standard `frk+deu` model config. Finally, after the training process, all pages again with the final training model.

OCR was done with Tesseract 4.x, training used a slighty adopted version of tesstrain.

## Training data

Training data pairs are located in `data` - subfolder. They  consist of more than 16.000 line images (tif-format) and corresponding textual groundtruth transcriptions.

*Attenzione*  
Downloading / cloning this repository might take some time depending on your network connection!

## Additional resources

Additional resources can be found inside the `resources` directory. Besides rudimentary `*.number` and `.punc` files it also contains the `*.wordlist` file that might be used final `*. traineddata`.

The wordlist contains more than 25.000 entries (double checked). Feel free to use it as extension for custom models related to german historical newspapers (1870-1945).

Further, it includes several Tesseract 4 unicharset-files, grabbed from <https://github.com/tesseract-ocr/langdata_lstm>.

## Training

### Installation Prerequisities

First of all, you need a tesseract installation, since tesstrain is like a middle-ware to run the actual training with tesseract's `lstmtrain` itself. Please install tesseract from `ppa:alex-p/tesseract-ocr` or compile yourself. The training at ULB used tesseract 4.x

Next, get a base model to start from.

* `frk`: <https://github.com/tesseract-ocr/tessdata_best/raw/master/frk.traineddata>
* `Fraktur`: <https://github.com/tesseract-ocr/tessdata_best/raw/master/script/Fraktur.traineddata>
* `GT4Hist`: <https://ub-backup.bib.uni-mannheim.de/~stweil/ocrd-train/data/Fraktur_5000000/Fraktur_5000000_0.466.traineddata>

Please note:  
_The language configuration files that can be installed from official ubuntu 18.04-Repository **do not** fit for training!_

### Run Training

*Please note*  
Base model configurations have to be placed in the tesseract `tessdata` configuration location, i.e. `/usr/share/tesseract-ocr/4.00/tessdata/` for tesseract 4.x.

The `TRAIN_DATA_PATH` must be an absolute local path. Feel free to use the training pairs from the `data`-folder or use your own.

Start training by executing `./train-local.sh`.
