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




# from chatgpt
output_dir="/rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/amo_test_experiment"
cd /rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/amo_test_experiment
# Get a list of all unique file names in the subdirectories
file_names=$(find . -type f -name "atmos_monthly_interp_new_height_temp.nc" -exec basename {} \; | sort)

# Loop over each unique file name
for file_name in $file_names; do
    # Find all files with the current name
    files=$(find . -type f -name "$file_name")
    echo "${files[@]}"
    # If more than one file with this name exists, merge them
    if [ $(echo "$files" | wc -l) -gt 1 ]; then
        # Define the output file path
        output_file="$output_dir/$file_name"

        # Merge the files using cdo
        echo "Merging files for $file_name into $output_file"
        cdo mergetime $files "$output_file"
    else
        echo "Only one file found for $file_name, no merge needed."
    fi
done