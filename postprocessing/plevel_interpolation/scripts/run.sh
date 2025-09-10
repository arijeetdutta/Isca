#!/bin/bash
#SBATCH --account=bridge_monsoon
#SBATCH --job-name=isca_postrprocess
#SBATCH --time=03:00:00
##SBATCH --nodes=1
##SBATCH --mem-per-cpu=10G
#SBATCH --ntasks=32
##SBATCH --mem-per-cpu=1000G
##SBATCH --mail-type=ALL
#SBATCH --partition=standard
#SBATCH --qos=high
#SBATCH --output=slurm_dump/%j.out


set -e
conda activate isca_env_no_comp
source /home/users/duttaay/Isca/src/extra/env/jasmin

python run_plevel.py
