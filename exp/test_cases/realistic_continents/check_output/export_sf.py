import matplotlib.pyplot as plt; import seaborn as sns; import numpy as np; import xarray as xr
import os;  from pathlib import Path; import pandas as pd
import glob; import dask


import sys; import subprocess
sys.path.append('/rds/homes/d/duttaay/pyfuncs')
from pyutil import *


ds_amo = xr.open_dataset('/rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/amo_test_experiment/output.nc',decode_times=False)
ds = xr.open_dataset('/rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/realistic_continents_fixed_sst_test_experiment/atmos_monthly_interp_new_height_temp.nc',decode_times=False)

ds['time'] = pd.date_range('01-01-1900',periods=600,freq='M')
ds_amo['time'] = pd.date_range('01-01-1900',periods=600,freq='M')