#!/bin/sh

./mpirun_script.sh ./Allen --mdf `find /scratch/dcampora/allen_data/201907/mdf -path "*.mdf" -print0 | sort -z | tr '\0' ',' | sed 's/.$//'`
