#!/bin/bash

# Prepare JSON
Rscript R/prepare_json_params.R \
        -i "${INPUT_DIR}" \
        -o "${OUTPUT_DIR}" \
        -m "${MAP}" \
        -t "${LOOKUP_TABLE}" \
        -l "${LOCATIONS}" \
        -p "${PARAMETERS}"

# Prepare input files with HyperQueue
# This is based on
# https://docs.csc.fi/apps/hyperqueue/

# HyperQueue server directory
export HQ_SERVER_DIR="${PWD}/hq-server-${SLURM_JOB_ID}"
mkdir -p "${HQ_SERVER_DIR}"

# Remove the server directory at exit
trap "rm -rf ${HQ_SERVER_DIR}" EXIT

# Start the server in the background (&) and wait until it has started
hq server start &
until hq job list &>/dev/null ; do sleep 1 ; done

hq worker start &
hq worker wait 1

# hq submit --from-json "${INPUT_DIR}/locations.json" \
#    --cpus "${CPUS}" \
#     --stderr "hq-${SLURM_JOB_ID}-%{TASK_ID}.stderr" \
#     --stdout "hq-${SLURM_JOB_ID}-%{TASK_ID}.stdout" \
#     /scripts/prepare_beehave_input_hq_cloud.sh
# 
# hq job wait all
# Compute Beehave simulation with HyperQueue
mkdir "${OUTPUT_DIR}"

hq submit \
    --log="${INPUT_DIR}/hq_log" \
    --from-json "${INPUT_DIR}/netlogo.json" \
    --cpus "${CPUS}" \
    --stderr "hq-${SLURM_JOB_ID}-%{TASK_ID}.stderr" \
    --stdout "hq-${SLURM_JOB_ID}-%{TASK_ID}.stdout" \
    --env NETLOGO_VERION="${NETLOGO_VERSION}" \
    --env NETLOGO_HOME="${NETLOGO_HOME}" \
    --env MODEL_PATH="${MODEL_PATH}" \
    /scripts/run_beehave_hq_cloud.sh

# Wait until all jobs have finished, shut down the HyperQueue workers and server
hq job wait all
hq worker stop all
hq server stop
