#!/bin/bash -l
#SBATCH -J test
#SBATCH --partition=small
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:15:00

date
echo $SLURM_JOB_ID

# Use correct file paths here
MODEL_PATH="data/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo"
SIF="beehave_0.3.1.sif"
RSCRIPT="R/run_beehave.R"
JSON_INPUT_PATH="data/single_execution.json"

####################################
# No need to edit the lines below
####################################

# NetLogo pollutes home directory with .java and .netlogo directories, so
# we use a temporary home directory in singularity
TMP_HOME=`mktemp -d -p /tmp`

# Create a base directory manually to suppress messages from NetLogo
mkdir -p $TMP_HOME/.java/.userPrefs

# Remove temporary home directory at exit
# Note: One could do "rm -rf $TMP_HOME", but we don't do it as a safeguard in case
# someone would modify TMP_HOME to be the real home and get everything erased there
trap "rm -r $TMP_HOME/.java $TMP_HOME/.netlogo; rmdir $TMP_HOME" EXIT

# Make model path env variable visible in Rscript
export MODEL_PATH

# Run nlrx
singularity exec --home "$TMP_HOME" --bind "$PWD" "$SIF" Rscript "$RSCRIPT" "$(cat $JSON_INPUT_PATH)"
date

