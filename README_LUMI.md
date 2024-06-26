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

Download `BEEHAVE_BeeMapp2016.zip` with test data from https://beehave-model.net/download/. Direct link:

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


## Large-scale calculation

Download map (source https://doi.org/10.1594/PANGAEA.910837):

    wget https://hs.pangaea.de/Maps/Germany/Preidl-etal_2020/APiC_Agricultural-Land-Cover-Germany_RSE-2020.zip
    unzip APiC_Agricultural-Land-Cover-Germany_RSE-2020.zip

Prepare data directory:

    mkdir -p test/large/
    cp data/NectarPollenLookUp.csv test/large/
    cp data/parameters.csv test/large/
    cp APiC_Agricultural-Land-Cover-Germany_RSE-2020/preidl-etal-RSE-2020_land-cover-classification-germany-2016.tif* test/large/
    cp .../germany_grid_10km.csv test/large/

Create `locations.json` and `netlogo.json` from input files:

    bash scripts/prepare.lumi.sh test/large

Process `locations.json` to input files:

    export RDWD_CACHEDIR="$PWD/rdwd_cache"
    mkdir -p "$RDWD_CACHEDIR"
    sbatch -J beehave_prepare -N 1 -t 1:00:00 scripts/submit_hq.lumi.sh R/prepare_beehave_input.R test/large/locations.json
    # This should take about 20 mins

Run BEEHAVE model:

    # Using the standard partition (running in parallel
    # 64 BEEHAVE instances per node as extra RAM/instance needed;
    # BEEHAVE uses threading too)
    sbatch -J beehave_run -N 8 --cpus-per-task=64 -t 4:00:00 scripts/submit_hq.lumi.sh R/run_beehave.R test/large/netlogo.json
    # This should take about 1 hour

    # Alternatively twice more RAM/instance
    sbatch -J beehave_run -N 8 --cpus-per-task=32 -t 4:00:00 scripts/submit_hq.lumi.sh R/run_beehave.R test/large/netlogo.json
    # This should take about 1.5 hours

    # Alternatively using the partition with even more RAM/instance
    sbatch -J beehave_run -N 1 --cpus-per-task=128 -t 8:00:00 -p largemem scripts/submit_hq.lumi.sh R/run_beehave.R test/large/netlogo.json
    # This should take about 5 hours


### Known issues

* Race condition with the shared `RDWD_CACHEDIR` and hyperqueue execution (one process might try to read cached file before other process has written it)

