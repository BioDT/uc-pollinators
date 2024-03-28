# Running on LUMI

## Preparation

### Set up container

Pull the pre-built image (choose the desired `<version>`):

    singularity pull --docker-login docker://ghcr.io/biodt/beehave:<version>

This creates singularity image file `beehave_<version>.sif`.

Note that the image is for now private, which means that login is required.
Follow [these instructions](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#creating-a-personal-access-token-classic)
and create a classic personal access token with scope 'read:packages'.
Then, use your GitHub username and the created token in the login prompt of `singularity pull`.

### Set up HyperQueue

Download hq binary release:

    mkdir -p bin
    wget https://github.com/It4innovations/hyperqueue/releases/download/v0.15.0/hq-v0.15.0-linux-x64.tar.gz -O - | tar -xzf - -C bin


## A test case

### Download test data

Download test data (in `BEEHAVE_BeeMapp2016.zip`):

    wget --content-disposition 'https://beehave-model.net/?smd_process_download=1&download_id=974'
    unzip BEEHAVE_BeeMapp2016.zip -d test

### Single execution

Run script:

    sbatch scripts/submit_single.lumi.sh

Standard output will go to file `slurm-*.out`.

### HyperQueue execution

Run script:

    sbatch -p small --cpus-per-task=2 --mem-per-cpu=8G -t 0:15:00 scripts/submit_hq.lumi.sh R/run_beehave.R data/hq_execution.json

Standard output will go to files in `hq-*.stderrout.zip`.


## Full-scale demo

Details of execution:

    export TMP_HOME=`mktemp -d -p /tmp`
    mkdir -p $TMP_HOME/.java/.userPrefs

    singularity exec --home "$TMP_HOME" --bind "$PWD" beehave_0.3.2.sif Rscript R/test_prepare_json.R

    mkdir -p data/input/locations
    mkdir -p data/output

    sbatch -J prepare -N 10 -t 1:00:00 scripts/submit_hq.lumi.sh R/prepare_input.R data/input/locations.json
    sbatch -J run     -N 2  -t 8:00:00 --cpus-per-task=32 scripts/submit_hq.lumi.sh R/run_beehave.R data/input/netlogo.json

