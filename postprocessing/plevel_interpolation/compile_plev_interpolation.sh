#!/usr/bin/env bash
#Script that compiles the plev.x executable

cd ./exec

source $GFDL_BASE/src/extra/env/$GFDL_ENV
# source $GFDL_BASE/src/extra/env/uob-bbr

../bin/mkmf -p plev.x -t ../bin/mkmf.template.uob-bbr -c "-Duse_netCDF" -a ../src ../src/path_names ../src/shared/mpp/include ../src/shared/include

make -f Makefile
