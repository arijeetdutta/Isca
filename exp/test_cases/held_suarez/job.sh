#!/bin/bash
#SBATCH --ntasks=16
#SBATCH --time=25:0
#SBATCH --mail-type=ALL
#SBATCH --account=geenr-bridge-monsoon
#SBATCH --qos=bbdefault

set -e

module purge; module load bluebear
source ~/.bashrc
conda activate isca_env
python held_suarez_test_case.py
