cd /rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/realistic_continents

# check for files
# for d in */; do [ -d "$d" ] && [ -f "${d}atmos_6hourly_interp_new_height_temp.nc" ] && echo "File found in $d" || echo "File NOT found in $d"; done



# cd /rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/na_sst
# find . -type f -name "atmos_6hourly.nc" -exec rm -f {} +
find . -type f -name "atmos_6hourly.nc" -exec rm -f {} +
