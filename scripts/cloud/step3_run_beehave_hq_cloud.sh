#!/bin/bash

#export JAVA_HOME="/usr/lib64/jvm/java-17-openjdk-17"

Rscript /R/step3_run/step3_run_beehave.R \
        -u "${HQ_ENTRY}" \
        -v "${NETLOGO_VERSION}" \
        -n "${NETLOGO_HOME}" \
        -m "${MODEL_PATH}"
