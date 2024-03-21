#!/bin/bash

export JAVA_HOME="/usr/lib64/jvm/java-17-openjdk-17"

Rscript /R/run_beehave_params.R \
        -p "${HQ_ENTRY}" \
        -v "${NETLOGO_VERSION}" \
        -n "${NETLOGO_HOME}" \
        -m "${MODEL_PATH}"

