#!/bin/bash

ml R

JAVA_HOME="/scratch/project/open-27-31/jdk-17.0.5"
NETLOGO_HOME="/scratch/project/open-27-31/NetLogo 6.2.0"
MODEL_PATH="/scratch/project/open-27-31/uc-beehave-execution-scripts/data/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo"

Rscript R/run_beehave.R "${HQ_ENTRY}" "$JAVA_HOME" "$NETLOGO_HOME" "$MODEL_PATH"

