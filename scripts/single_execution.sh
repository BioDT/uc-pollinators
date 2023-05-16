#!/bin/bash

# We assume it is executed from the R project home directory.
export JAVA_HOME="/Users/martinovic/beehave/jdk-17.0.6.jdk/Contents/Home/"
export NETLOGO_HOME="/Users/martinovic/beehave/NetLogo 6.2.0"
export NETLOGO_VERSION="6.2.0"
export MODEL_PATH="data/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo"

# Read JSON input and pass it as an argument for the Rscript call
JSON_INPUT=$(cat data/single_execution.json && echo .)
JSON_INPUT=${JSON_INPUT%.}

Rscript R/run_beehave.R "$JSON_INPUT"
