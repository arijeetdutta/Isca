#!/bin/bash


ddir=/rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/realistic_continents_fixed_sst_test_experiment
cd $ddir

# Find directories with both letters and numbers in their names
dirs=$(find . -type d -name '*[a-zA-Z]*' | grep -E '[0-9]' | sort -V)

# Iterate over sorted directories
for dir in $dirs; do

	    echo "Processing directory: $dir"
	    numbers="${dir//[^0-9]/}"
#	    echo $numbers
	    echo "creating tmp directory"
   	    mkdir -p $dir/tmp/
	    echo "copying files to tmp and renaming"
            cp $dir/atmos_monthly_interp_new_height_temp.nc $dir/tmp/$numbers.nc
	    ls -l $dir/tmp/$numbers.nc
	    cd $dir/tmp/$numbers.nc
	    echo "cdo mergetime"
	    cdo mergetime $dir/tmp/*.nc $dir/output.nc
	    echo "removing tmp"
	    rm -rf $dir/tmp/

done

