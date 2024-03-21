#!/bin/bash

# JSON PREPARATION
export R_PATH="R"
export DATA_PATH="data/test"
export SCRIPT_PATH="scripts"
export INPUT_DIR="/data"
export OUTPUT_DIR="/data/output"
export MAP="preidl-etal-RSE-2020_land-cover-classification-germany-2016.tif"
export LOOKUP_TABLE="NectarPollenLookUp.csv"
export LOCATIONS="locations.csv"
export PARAMETERS="parameters.csv"
export NETLOGO_VERSION="6.3.0"
export NETLOGO_HOME="/NetLogo 6.3.0"
export MODEL_PATH="/data/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo"
export CPUS=1

docker run \
           -v "$PWD/${SCRIPT_PATH}":"/scripts" \
           -v "$PWD/${R_PATH}":"/R" \
           -v "$PWD/${DATA_PATH}":"${INPUT_DIR}" \
           -e INPUT_DIR="${INPUT_DIR}" \
           -e OUTPUT_DIR="${OUTPUT_DIR}" \
           -e MAP="${MAP}" \
           -e LOOKUP_TABLE="${LOOKUP_TABLE}" \
           -e LOCATIONS="${LOCATIONS}" \
           -e PARAMETERS="${PARAMETERS}" \
           -e NETLOGO_VERION="${NETLOGO_VERSION}" \
           -e NETLOGO_HOME="${NETLOGO_HOME}" \
           -e MODEL_PATH="${MODEL_PATH}" \
           -e CPUS="${CPUS}" \
           --cpus "${CPUS}" \
           --platform linux/amd64 \
           --entrypoint /scripts/run_docker_flow.sh \
           ghcr.io/biodt/beehave:0.3.6 

# 
# docker run \
# --rm -it \
#            -v "$PWD/${SCRIPT_PATH}":"/scripts" \
#            -v "$PWD/${R_PATH}":"/R" \
#            -v "$PWD/${DATA_PATH}":"/data" \
#            -e INPUT_DIR="/data" \
#            -e OUTPUT_DIR="${OUTPUT_DIR}" \
#            -e MAP="${MAP}" \
#            -e LOOKUP_TABLE="${LOOKUP_TABLE}" \
#            -e LOCATIONS="${LOCATIONS}" \
#            -e PARAMETERS="${PARAMETERS}" \
#            -e NETLOGO_VERION="${NETLOGO_VERSION}" \
#            -e NETLOGO_HOME="${NETLOGO_HOME}" \
#            -e MODEL_PATH="${MODEL_PATH}" \
#            -e CPUS="${CPUS}" \
#            --platform linux/amd64 \
#            --entrypoint bash \
#            ghcr.io/biodt/beehave:0.3.6
