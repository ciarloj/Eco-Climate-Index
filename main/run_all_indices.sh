#!/bin/bash
{
set -eo pipefail

## Set inputs
nam=EOBS-010-v25e
frq=day

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
mdir=$hdir/main
idir=$mdir/indices

if [ $nam = MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6 ]; then
  dat=RCMs
  yrs=1970-2005
  fcs=1986-2005
elif [ $nam = EOBS-010-v25e ]; then
  dat=OBS
  yrs=1985-2021
  fcs=1995-2014
  vars="pr tas tasmax tasmin sfcWind orog"
fi
vars="pr tas tasmax tasmin"
din=$hdir/data/$dat/$nam

for v in $vars; do
  [[ $v = pr      ]] && indices="cdd r99 prsum"
  [[ $v = tas     ]] && indices="hwfi cwfi tasmean"
  [[ $v = tasmax  ]] && indices="tasmaxmax tasmaxmean"
  [[ $v = tasmin  ]] && indices="tasminmin tasminmean"
  [[ $v = sfcWind ]] && indices="fg6bft windmean"
  [[ $v = orog    ]] && indices="orog"
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
