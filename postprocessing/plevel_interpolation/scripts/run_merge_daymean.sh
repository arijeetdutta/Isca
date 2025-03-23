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


ddir=/rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/idealised_land
cd $ddir
echo "creating tmp directory"
mkdir -p $ddir/tmp/
rm -rf $ddir/tmp/*


# for i in $(seq -w 000 600); do
for i in $(seq -f "%04g" 121 660); do
    dir="/rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/idealised_land/run$i"
    # file_path="$dir/atmos_6_hourly_interp_new_height_temp.nc"
    
    # Check if the directory exists
    if [ -d "$dir" ]; then

        echo "Processing directory: $dir"
        cp $dir/atmos_daily_mean.nc $ddir/tmp/$i.nc
        ls -l $ddir/tmp/$i.nc

    else
        echo "Directory not found: $dir"
    fi
done


cd $ddir/tmp/
rm -rf $ddir/output.nc
echo "cdo mergetime"
cdo mergetime $ddir/tmp/*.nc $ddir/output.nc
echo "removing tmp"
rm -rf $ddir/tmp/
ls -l $ddir/output.nc
echo "completed"

