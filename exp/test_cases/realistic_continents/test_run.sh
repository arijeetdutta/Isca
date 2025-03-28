#!/bin/bash
#SBATCH --job-name=Isca_fixed_sst 
##SBATCH -D . # set working directory to .
##SBATCH -p pq # submit to the parallel queue
#SBATCH --time=56:00:00
#SBATCH --nodes=1
##SBATCH --mem-per-cpu=6400M
#SBATCH --ntasks=32
##SBATCH --ntasks-per-node=65
##SBATCH --mail-type=ALL
#SBATCH --account=geenr-bridge-monsoon
#SBATCH --qos=bbdefault
#SBATCH --output=slurm_dump/%j.out

set -e

module purge; module load bluebear
source "/rds/homes/d/duttaay/miniforge3/etc/profile.d/conda.sh"
conda activate isca_env

python test_sst.py
