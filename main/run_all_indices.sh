#!/bin/bash
{
set -eo pipefail

## Set inputs
nam=$1 #EOBS-010-v25e
frq=day

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
mdir=$hdir/main
idir=$mdir/indices

# [ $nam = EOBS-010-v25e ]; then
dat=$2 #OBS
yrs=$3 #1985-2021 #years available
fcs=$4 #1995-2014 #years to study
vars=$5 #"pr tas tasmax tasmin sfcWind orog popden"
din=$hdir/data/$dat/$nam

for v in $vars; do
  [[ $v = pr      ]] && indices="cdd r99 prsum"
  [[ $v = tas     ]] && indices="hwfi cwfi tasmean"
  [[ $v = tasmax  ]] && indices="tasmaxmax tasmaxmean"
  [[ $v = tasmin  ]] && indices="tasminmin tasminmean"
  [[ $v = sfcWind ]] && indices="fg6bft windmean"
  [[ $v = orog    ]] && indices="orog"
  [[ $v = popden  ]] && indices="popdenmean"
  for i in $indices; do
    bs="bash"
    [[ $i = r99    ]] && bs="slurm"
    [[ $i = hwfi   ]] && bs="slurm"
    [[ $i = cwfi   ]] && bs="slurm"
    [[ $i = fg6bft ]] && bs="slurm"
    if [ $bs = "slurm" ]; then
      j=${i}_${nam}
      o=logs/${j}.o
      e=logs/${j}.e
      echo '$$ Submitting '"$idir/${v}_${i}.sh"
      sbatch -J $j -o $o -e $e -p esp -t 24:00:00 $idir/${v}_${i}.sh $nam $frq $yrs $fcs $din
    elif [ $bs = "bash" ]; then
      echo '$$ Running '"$idir/${v}_${i}.sh"
      bash $idir/${v}_${i}.sh $nam $frq $yrs $fcs $din
    fi
  done
done

}
