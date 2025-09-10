#!/usr/bin/env bash
#Script that compiles the plev.x executable
source ~/.bashrc
#conda activate isca_env
conda activate isca_env_no_comp

cd ./exec

source $GFDL_BASE/src/extra/env/$GFDL_ENV

../bin/mkmf -p plev.x -t ../bin/mkmf.template.jasmin -c "-Duse_netCDF" -a ../src ../src/path_names ../src/shared/mpp/include ../src/shared/include

make -f Makefile
