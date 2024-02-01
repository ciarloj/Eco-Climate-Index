#!/bin/bash
#SBATCH -J pca
#SBATCH -o logs/pca.o
#SBATCH -e logs/pca.e
#SBATCH -t 24:00:00
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jciarlo@ictp.it
#SBATCH -p esp
{
set -eo pipefail
startTime=$(date +"%s" -u)

spc=$1 #xylocopa-violacea  
obs=iNaturalist
nam=EOBS-010-v25e
#nboot=$4 #1 #5000  # number of bootstap replications

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
dat=OBS
fcs=1980-2010

nobs=$( cat data/OBS/$obs/${spc}_${obs}.csv | wc -l )
ntrg=5000 # target number of observations (to reach with boot if required)
nboot=$( echo "scale=4; $ntrg / $nobs" | bc )
nboot=$( printf "%.0f\n" "$nboot" ) #round
[[ $nboot -lt 1 ]] && nboot=1


idir=data/$dat/$nam/index/$obs/boot_${nboot}/standard

echo "##########################################"
echo "## Principal Component Analysis"
echo "## spc   = $spc"
echo "## obs   = $obs"
echo "## meteo = $nam"
echo "## nboot = $nboot"
echo "##########################################"

flog=$( basename $( eval ls $idir/${spc}_${obs}_${nam}.csv ) .csv )
script=tools/pca_check.R
#echo $idir/$flog
Rscript $script "$flog $idir" 

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
