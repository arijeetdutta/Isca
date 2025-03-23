#!/bin/bash

#SBATCH --job-name=dailyclim
##SBATCH -D . # set working directory to .
##SBATCH -p pq # submit to the parallel queue
#SBATCH --time=30:00
##SBATCH --nodes=1
#SBATCH --mem-per-cpu=10G
#SBATCH --ntasks=16
##SBATCH --ntasks-per-node=65
##SBATCH --mail-type=ALL
#SBATCH --account=geenr-bridge-monsoon
#SBATCH --qos=bbdefault
#SBATCH --output=slurm_dump/%j.out

set -e
module purge; module load bluebear
module load CDO/1.9.10-gompi-2020b

cd /rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/idealised_land
cdo ydaymean output.nc idealised_land_45_years_dailyclim_topog_smopth_0.8.nc
