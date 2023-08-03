#!/bin/bash
#SBATCH -N 1
#SBATCH -p esp
#SBATCH -t 24:00:00
#SBATCH -o logs/points.o
#SBATCH -e logs/points.e
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jciarlo@ictp.it
{
set -eo pipefail

obs=$1
export spc=$( basename $obs .csv | cut -d_ -f1 )
export dbs=$( basename $obs .csv | cut -d_ -f2 )
export dom=$( basename $obs .csv | cut -d_ -f3 )
o=logs/points_${spc}_${dbs}_${dom}.out
ncl -Q tools/plot_obs_points.ncl | grep -v 'replacing with missing value' # >>$o 2>>$o

}

