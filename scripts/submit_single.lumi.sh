#!/bin/bash -l
#SBATCH -J test
#SBATCH --partition=small
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:15:00

# Use correct file paths here
RUN="./scripts/run.lumi.sh"
JSON_INPUT_PATH="data/single_execution.json"

####################################
# No need to edit the lines below
####################################

# Run
"$RUN" "$(cat $JSON_INPUT_PATH)"
