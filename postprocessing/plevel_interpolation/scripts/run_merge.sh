#!/bin/bash
#SBATCH --job-name=cdo_merge
##SBATCH -D . # set working directory to .
##SBATCH -p pq # submit to the parallel queue
#SBATCH --time=1:00:00
#SBATCH --nodes=1
##SBATCH --mem-per-cpu=6400M
#SBATCH --ntasks=32
##SBATCH --ntasks-per-node=65
##SBATCH --mail-type=ALL
#SBATCH --account=geenr-bridge-monsoon
#SBATCH --qos=bbdefault
#SBATCH --output=slurm_dump/%j.out

set -e
module purge
module load bear-apps/2023a
module load CDO/2.2.2-gompi-2023a


ddir=/rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/realistic_continents_fixed_sst_test_experiment
# ddir=/rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/amo_test_experiment
cd $ddir

echo "creating tmp directory"
mkdir -p $ddir/tmp/

# Find directories with both letters and numbers in their names
dirs=$(find . -type d -name '*[a-zA-Z]*' | grep -E '[0-9]' | sort -V)

# Iterate over sorted directories
for dir in $dirs; do

	    # echo "Processing directory: $dir"
	    numbers="${dir//[^0-9]/}"

	    echo "copying files to tmp and renaming"
        cp $dir/atmos_monthly_interp_new_height_temp.nc $ddir/tmp/$numbers.nc
	    ls -l $ddir/tmp/$numbers.nc
	    

done

cd $ddir/tmp/
rm -rf $ddir/output.nc
echo "cdo mergetime"
cdo mergetime $ddir/tmp/*.nc $ddir/output.nc
echo "removing tmp"
rm -rf $ddir/tmp/
ls -l $ddir/output.nc
echo "completed"