#!/bin/bash

export R_BOX_PATH="/"
# export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

# Prepare JSON
Rscript /R/step1_hq/step1_prepare_hq_jsons.R \
        -i "${INPUT_DIR}" \
        -o "${OUTPUT_DIR}" \
        -m "${MAP}" \
        -t "${LOOKUP_TABLE}" \
        -l "${LOCATIONS}" \
        -p "${PARAMETERS}" \
        -s "${SIMULATIONS}"

# Prepare input files with HyperQueue
# This is based on
# https://docs.csc.fi/apps/hyperqueue/

# HyperQueue server directory
export HQ_SERVER_DIR="${PWD}/hq-server"
mkdir -p "${HQ_SERVER_DIR}"

# Remove the server directory at exit
trap "rm -rf ${HQ_SERVER_DIR}" EXIT

# Start the server in the background (&) and wait until it has started
hq server start &
until hq job list &>/dev/null ; do sleep 1 ; done

hq worker start &
hq worker wait 1

hq submit --from-json "${INPUT_DIR}/locations.json" \
   --cpus "${CPUS}" \
    --stderr "${INPUT_DIR}/hq-%{TASK_ID}.stderr" \
    --stdout "${INPUT_DIR}/hq-%{TASK_ID}.stdout" \
    --env R_BOX_PATH=${R_BOX_PATH} \
    /scripts/step2_prepare_beehave_input_hq_cloud.sh

hq job wait all
# Compute Beehave simulation with HyperQueue
mkdir "${OUTPUT_DIR}"

hq submit \
    --from-json "${INPUT_DIR}/netlogo.json" \
    --cpus "${CPUS}" \
    --stderr "${INPUT_DIR}/hq-beehave-%{TASK_ID}.stderr" \
    --stdout "${INPUT_DIR}/hq-beehave-%{TASK_ID}.stdout" \
    --env NETLOGO_JAR_PATH="${NETLOGO_JAR_PATH}" \
    --env MODEL_PATH="${MODEL_PATH}" \
    --env R_BOX_PATH=${R_BOX_PATH} \
    /scripts/step3_run_beehave_hq_cloud.sh

# Wait until all jobs have finished, shut down the HyperQueue workers and server
hq job wait all
hq worker stop all
hq server stop
