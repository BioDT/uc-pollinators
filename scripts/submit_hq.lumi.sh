#!/bin/bash -l
#SBATCH -J test
#SBATCH --partition=small
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=00:15:00

# Use correct file paths here
RUN="./scripts/run.lumi.sh"
HQ_JSON_INPUT_PATH="data/hq_execution.json"

# Add hq to PATH
export PATH="$PWD/bin:$PATH"

####################################
# No need to edit the lines below
####################################

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

# Start the workers (one per node, in the background) and wait until they have started
srun --exact --cpu-bind=none --mpi=none hq worker start --cpus=${SLURM_CPUS_PER_TASK} &
hq worker wait "${SLURM_NTASKS}"

# Run the script with HyperQueue
hq submit --from-json "$HQ_JSON_INPUT_PATH" \
    --cpus 1 \
    --stderr "hq-${SLURM_JOB_ID}-%{TASK_ID}.stderr" \
    --stdout "hq-${SLURM_JOB_ID}-%{TASK_ID}.stdout" \
    "$RUN"

# Wait until all jobs have finished, shut down the HyperQueue workers and server
hq job wait all
hq worker stop all
hq server stop
