import numpy as np; import os;  from pathlib import Path; import glob; import sys; import subprocess


file_list = sorted(glob.glob('/rds/homes/d/duttaay/geenr-bridge-monsoon/isca_data/amo_test_experiment/run????/atmos_monthly_interp_new_height_temp.nc'))

import re
def get_numbers_from_filename(filename):
    return re.findall(r'\d+', filename)

def find_missing_numbers(nums):
    if not nums:
        return []

    # Create a set of the numbers in the list
    num_set = set(nums)

    # Find the range of numbers (min to max)
    min_num, max_num = min(nums), max(nums)
    
    # Create a set of the full range
    full_set = set(range(min_num, max_num + 1))
    
    # Find missing numbers by subtracting num_set from full_set
    missing_numbers = full_set - num_set
    
    return sorted(missing_numbers)


a = []
for i in range(len(file_list)):
    num = get_numbers_from_filename(file_list[i])
    # print(int(num[0]))
    a.append(int(num[0]))

print(find_missing_numbers(a))