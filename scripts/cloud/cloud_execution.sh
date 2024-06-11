#!/bin/bash

# JSON PREPARATION
# export R_PATH="$1"
export DATA_PATH="$1" 
# export SCRIPT_PATH="$1"
export INPUT_DIR="/data"
export OUTPUT_DIR="/data/output"
export MAP="map.tif"
export LOOKUP_TABLE="lookup_table.csv"
export LOCATIONS="locations.csv"
export PARAMETERS="parameters.csv"
export SIMULATIONS="simulation.csv"
export NETLOGO_JAR_PATH="/NetLogo 6.3.0/lib/app/netlogo-6.3.0.jar"
#export NETLOGO_VERSION="6.3.0"
#export NETLOGO_HOME="/NetLogo 6.3.0"
export MODEL_PATH="${INPUT_DIR}/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo" # This assumes model is put into the same folder as inputs
export CPUS=1

docker run \
 -v "${PWD}/${DATA_PATH}":"${INPUT_DIR}" \
 -e INPUT_DIR="${INPUT_DIR}" \
 -e OUTPUT_DIR="${OUTPUT_DIR}" \
 -e MAP="${MAP}" \
 -e LOOKUP_TABLE="${LOOKUP_TABLE}" \
 -e LOCATIONS="${LOCATIONS}" \
 -e PARAMETERS="${PARAMETERS}" \
 -e SIMULATIONS="${SIMULATIONS}" \
 -e MODEL_PATH="${MODEL_PATH}" \
 -e NETLOGO_JAR_PATH="${NETLOGO_JAR_PATH}" \
 -e CPUS="${CPUS}" \
 --cpus "${CPUS}" \
 --platform linux/amd64 \
 --entrypoint /scripts/cloud/run_docker_flow.sh \
 ghcr.io/biodt/beehave:0.3.10

exit
# /scripts/cloud/run_docker_flow.sh
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
