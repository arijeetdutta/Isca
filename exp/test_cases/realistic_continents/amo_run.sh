#!/bin/bash
#SBATCH --job-name=Isca_amo_run 
##SBATCH -D . # set working directory to .
##SBATCH -p pq # submit to the parallel queue
#SBATCH --time=9:00:00
#SBATCH --nodes=1
##SBATCH --mem-per-cpu=6400M
#SBATCH --ntasks=16
##SBATCH --ntasks-per-node=65
##SBATCH --mail-type=ALL
#SBATCH --account=geenr-bridge-monsoon
#SBATCH --qos=bbdefault
#SBATCH --output=slurm_dump/%j.out

set -e
module purge; module load bluebear
source ~/.bashrc
conda activate isca_env

python amo_run.py
