#!/bin/bash
{
set -eo pipefail

## Set inputs
export nam=EOBS-010-v25e

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
ddir=$( ls -d $hdir/data/*/$nam )/index
if [ ! -d $ddir ]; then
  echo 'Path does not exist: '$ddir
  exit -1
fi

rdir=$ddir/pearson-correlation
mkdir -p $rdir
rlog=$rdir/r.log
plog=$rdir/p.log
pdir=$hdir/data/OBS/GPWv4/remap_$nam

here=$( pwd )
cd $ddir

  idxlist=" popden $( ls *.nc | cut -d_ -f2 | uniq )"
  nyrs=$( ls *_*_*_*.nc | cut -d_ -f4 | cut -d. -f1 | uniq | wc -l )
  export years=$( eval ls *_*_*_*.nc | cut -d_ -f4 | cut -d. -f1 | uniq )
  if [ $nyrs -ne 1 ]; then
    echo "Contains multiple ($nyrs) time periods."
    echo "  $years"
    exit -1 
  fi

cd $here

l=0
for i in $idxlist; do
  l=$(( l+1 ))
  [[ $l = 1 ]] && header="x"
  rrow="$i"
  prow="$i"
  export idx1=$i
  file="$ddir/*_${i}_${nam}_${years}.nc"
  [[ $idx1 = orog ]] && file="$ddir/*_${i}_${nam}.nc"
  [[ $idx1 = popden ]] && file="$pdir/${idx1}-mean_*.nc"
  export fil1=$( eval ls $file )
  export v1=$( basename $fil1 .nc | cut -d_ -f1 )

  for i2 in $idxlist; do
    [[ $l = 1 ]] && header="$header $i2"
    export idx2=$i2
    file="$ddir/*_${i2}_${nam}_${years}.nc"
    [[ $idx2 = orog ]] && file="$ddir/*_${i2}_${nam}.nc"
    [[ $idx2 = popden ]] && file="$pdir/${idx2}-mean_*.nc"
    export fil2=$( eval ls $file )
    export v2=$( basename $fil2 .nc | cut -d_ -f1 )
  
    nclout=$( ncl -nQ $hdir/tools/spatial_corr.ncl )
    v1=$( echo $nclout | cut -d' ' -f1 )
    v2=$( echo $nclout | cut -d' ' -f2 )
    rr=$( echo $nclout | cut -d' ' -f3 )
    pp=$( echo $nclout | cut -d' ' -f4 )
    rrow="$rrow $rr"
    prow="$prow $pp"
  done

  [[ $l = 1 ]] && echo $header
  echo $rrow

  [[ $l = 1 ]] && echo $header > $rlog
  [[ $l = 1 ]] && echo $header > $plog
  echo $rrow >> $rlog
  echo $prow >> $plog

done

}
