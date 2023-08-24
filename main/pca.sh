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

spc=$3 #xylocopa-violacea  
obs=$2 #iNaturalist
nam=$1 #EOBS-010-v25e
nboot=$4 #1 #5000  # number of bootstap replications

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
dat=$5 #OBS
fcs=$6 #1995-2014

idir=data/$dat/$nam/index/$obs/boot_${nboot}/standard
export bdir=$idir/pca
mkdir -p $bdir

echo "##########################################"
echo "## Principal Component Analysis"
echo "## spc   = $spc"
echo "## obs   = $obs"
echo "## meteo = $nam"
echo "## nboot = $nboot"
echo "##########################################"

flog=$( basename $( eval ls $idir/${spc}_${obs}_${nam}.csv ) .csv )
script=tools/pca.R
#echo $idir/$flog
Rscript $script "$flog $idir" 

#count the number of components
ncomp=$( ls $bdir/${spc}_${obs}_*_${nam}_comp*csv | wc -l )
echo ncomp = $ncomp

#count the numbero of liness
nlin=$( cat $bdir/${spc}_${obs}_*_${nam}_comp1.csv | wc -l )
echo nlin = $nlin

#...read the components?
for c in $( seq 1 $ncomp ); do
  echo "## preparing Comp. $c ##"
  cf=$( ls $bdir/${spc}_${obs}_*_${nam}_comp${c}.csv )
  of=$bdir/comp${c}_${nam}_${obs}_${spc}_${fcs}.nc
  for l in $( seq 1 $nlin ); do
    [[ $l -le 1 ]] && continue
    line=$( cat $cf | head -$l | tail -1 )
    var=$( echo $line | cut -d, -f1 | cut -d'"' -f2 )
    fac=$( echo $line | cut -d, -f2 )
    [[ $var = orog ]] && ivf=$( eval ls $idir/*_${var}_${nam}.nc ) || ivf=$( eval ls $idir/*_${var}_${nam}_${fcs}.nc )
    [[ $l = 2 ]] && CDO sub -chname,$var,comp $ivf -chname,$var,comp $ivf $of ## needs a base
    [[ $fac = NA ]] && continue
    echo "-- calculating $var with $fac --"
    CDO mulc,$fac -chname,$var,comp $ivf ${of}_tmp_${var}.nc
    CDO add $of ${of}_tmp_${var}.nc ${of}_tmp_add-${var}.nc
    mv ${of}_tmp_add-${var}.nc $of
    rm ${of}_tmp_${var}.nc
  done
  echo "## Component $c ready ##"
done

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
