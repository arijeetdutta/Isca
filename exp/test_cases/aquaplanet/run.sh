#!/bin/bash
#SBATCH --job-name=aq-Isca 
##SBATCH -D . # set working directory to .
##SBATCH -p pq # submit to the parallel queue
#SBATCH --time=24:00:00
#SBATCH --nodes=1
##SBATCH --mem-per-cpu=6400M
#SBATCH --ntasks=32
##SBATCH --ntasks-per-node=65
##SBATCH --mail-type=ALL
#SBATCH --account=geenr-bridge-monsoon
#SBATCH --qos=bbdefault
#SBATCH --output=slurm_dump/%j.out

set -e


# module purge; module load bluebear
# source "/rds/homes/d/duttaay/miniforge3/etc/profile.d/conda.sh"
# conda activate isca_env

source /rds/homes/d/duttaay/bridge/model/Isca/src/extra/env/uob-bbr


# module load bear-apps/2022b
# module load Miniforge3/24.1.2-0
# eval "$(${EBROOTMINIFORGE3}/bin/conda shell.bash hook)"
# source "${EBROOTMINIFORGE3}/etc/profile.d/mamba.sh"
# CONDA_ENV_PATH="/rds/projects/g/geenr-bridge-monsoon/isca_env"
# mamba activate "${CONDA_ENV_PATH}"

python test.py
