cd /rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/realistic_continents

for i in {121..125}; do
    if [ -f "run0${i}/atmos_6hourly.nc" ]; then
        
        rm "run0${i}/atmos_6hourly.nc"
        echo "removed"
    fi
done

