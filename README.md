# Beehave execution scripts

## LUMI

### Set up container

Pull the pre-built image on LUMI:
```bash
singularity pull --docker-login docker://ghcr.io/biodt/beehave:0.3.1
```
This creates singularity image file `beehave_0.3.1.sif`.

See [these instructions](https://github.com/BioDT/uc-beehave-singularity-for-lumi)
for information about login.

### Single execution

Example script:
```bash
sbatch scripts/submit_single.lumi.sh
```
Standard output will come to file `slurm-*.out`.

