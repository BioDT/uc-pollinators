#!/bin/bash

# Use correct file paths here
SIF="beehave_0.3.6.sif"
INPUT_DPATH="${1:-test/large}"
OUTPUT_DPATH="$INPUT_DPATH/results"

####################################
# No need to edit the lines below
####################################

# Create required directories
mkdir -p "$OUTPUT_DPATH"
mkdir -p "$INPUT_DPATH/locations"

# Temporary home directory in singularity in case scripts pollute real home
TMP_HOME=`mktemp -d -p /tmp`

# Remove temporary home directory at exit
trap "rm -rf $TMP_HOME" EXIT

# Run
export SINGULARITY_HOME="$TMP_HOME"
export SINGULARITY_BIND="/pfs,/scratch,/projappl,/project,/flash,/appl"
singularity exec "$SIF" Rscript R/prepare_json_params.R \
    -i "$INPUT_DPATH" \
    -m preidl-etal-RSE-2020_land-cover-classification-germany-2016.tif \
    -t NectarPollenLookUp.csv \
    -l germany_grid_10km.csv \
    -p parameters.csv \
    --buffer 5000 \
    -o "$OUTPUT_DPATH"

