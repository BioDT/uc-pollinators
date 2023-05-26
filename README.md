# Beehave execution scripts

## LUMI

### Preparation

#### Set up container

Pull the pre-built image on LUMI:
```bash
singularity pull --docker-login docker://ghcr.io/biodt/beehave:0.3.2
```
This creates singularity image file `beehave_0.3.2.sif`.

See [these instructions](https://github.com/BioDT/uc-beehave-singularity-for-lumi)
for information about login.

#### Set up HyperQueue

Download hq binary release:
```bash
mkdir -p bin
wget https://github.com/It4innovations/hyperqueue/releases/download/v0.15.0/hq-v0.15.0-linux-x64.tar.gz -O - | tar -xzf - -C bin
```

### Single execution

Example script:
```bash
sbatch scripts/submit_single.lumi.sh
```
Standard output will come to file `slurm-*.out`.

### HyperQueue execution

Example script:
```bash
sbatch scripts/submit_hq.lumi.sh
```
Standard output will come to files `hq-*.stdout`.


### Demo

```bash
export TMP_HOME=`mktemp -d -p /tmp`
mkdir -p $TMP_HOME/.java/.userPrefs

singularity exec --home "$TMP_HOME" --bind "$PWD" beehave_0.3.2.sif Rscript R/test_prepare_json.R

mkdir -p data/input/locations
mkdir -p data/output

sbatch -J prepare scripts/submit_hq.lumi.sh R/prepare_input.R data/input/locations.json
sbatch -J run     scripts/submit_hq.lumi.sh R/run_beehave.R   data/input/netlogo.json
```
