#!/bin/bash

# Use correct file paths here
MODEL_PATH="beehave/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo"
SIF="beehave_0.3.6.sif"
RSCRIPT="${RSCRIPT:-R/run_beehave.R}"

####################################
# No need to edit the lines below
####################################

# Get json input from command line or hyperqueue
JSON_INPUT="${JSON_INPUT:-$1}"
JSON_INPUT="${JSON_INPUT:-$HQ_ENTRY}"
[[ $JSON_INPUT ]] || >&2 echo "No json input"
[[ $JSON_INPUT ]] || exit 1

# NetLogo pollutes home directory with .java and .netlogo directories, so
# we use a temporary home directory in singularity
TMP_HOME=`mktemp -d -p /tmp`

# Create a base directory manually to suppress messages from NetLogo
mkdir -p $TMP_HOME/.java/.userPrefs

# Remove temporary home directory at exit
# Note: One could do "rm -rf $TMP_HOME", but we don't do it as a safeguard in case
# someone would modify TMP_HOME to be the real home and get everything erased there
trap "rm -rf $TMP_HOME/.java $TMP_HOME/.netlogo; rmdir $TMP_HOME" EXIT

# Make model path env variable visible in Rscript
export MODEL_PATH

# Run
export SINGULARITY_HOME="$TMP_HOME"
export SINGULARITY_BIND="/pfs,/scratch,/projappl,/project,/flash,/appl"
singularity exec "$SIF" Rscript "$RSCRIPT" "$JSON_INPUT"
