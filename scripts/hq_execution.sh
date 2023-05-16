#!/bin/bash

ml R

export JAVA_HOME="/scratch/project/open-27-31/jdk-17.0.5"
export NETLOGO_HOME="/scratch/project/open-27-31/NetLogo 6.2.0"
export NETLOGO_VERSION="6.2.0"
export MODEL_PATH="data/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo"

Rscript R/run_beehave.R "${HQ_ENTRY}"

