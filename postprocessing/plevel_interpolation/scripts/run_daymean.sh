#!/bin/bash

#SBATCH --job-name=run_daymean
##SBATCH -D . # set working directory to .
##SBATCH -p pq # submit to the parallel queue
#SBATCH --time=3:00:00
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
module load CDO/1.9.10-gompi-2020b

# Loop over each directory named run0xxx, where xxx ranges from 000 to 600
# for i in $(seq -w 000 600); do
for i in $(seq -f "%04g" 121 1200); do

    dir="/rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/aquaplanet_experiment/run$i"
    file_path="$dir/atmos_6_hourly_interp_new_height_temp.nc"
    
    # Check if the directory exists
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"

        # Check if the NetCDF file exists in the directory
        if [ -f "$file_path" ]; then
            # Perform the CDO daymean operation
            output_file="$dir/atmos_daily_mean.nc"
            cdo daymean "$file_path" "$output_file"

            echo "Daily mean calculated and saved to: $output_file"
        else
            echo "File not found: $file_path"
        fi
    else
        echo "Directory not found: $dir"
    fi
done

