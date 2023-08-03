#!/bin/bash
{
set -eo pipefail
startTime=$(date +"%s" -u)
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

export spc=xylocopa-violacea   
export obs=iNaturalist
export nam=EOBS-010-v25e
nboot=1 #5000  # number of bootstap replications

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
if [ $nam = MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6 ]; then
  dat=RCMs
  fcs=1986-2005
elif [ $nam = EOBS-010-v25e ]; then
  dat=OBS
  fcs=1995-2014
fi
ndir=data/$dat/$nam/index/$obs/boot_${nboot}/standard/pca
mdir=$ndir/mahalonobis
mkdir -p $mdir
script=$hdir/tools/stats.ncl

echo "##########################################"
echo "## spc   = $spc"
echo "## obs   = $obs"
echo "## model = $nam"
echo "##########################################"

#count the number of components
export ncomp=$( ls $ndir/${spc}_${obs}_*_${nam}_comp*csv | wc -l )
echo ncomp = $ncomp

export scrf=$( ls $ndir/${spc}_${obs}_*_${nam}_scores.csv )
combi=""
for c in $( seq 1 $ncomp ); do
  echo $c ..
  export cn=$c
  stt=$( ncl -nQ $script )
  avg=$( echo $stt | cut -d, -f2 )
  std=$( echo $stt | cut -d, -f1 )
  lim=$( echo $stt | cut -d, -f3 )

  echo "## $cn avg=$avg std=$std lim=$lim ##"
  ncf=$ndir/comp${cn}_${nam}_${obs}_${spc}_${fcs}.nc
  ouf=$mdir/$( basename $ncf )
  CDO addc,1 -mulc,-1 -divc,$lim -abs -divc,$std -subc,$avg $ncf $ouf

  if [ $c -lt $ncomp ]; then
    [[ $c = 1 ]] && combi="$combi mul $ouf" || combi="${combi} -mul $ouf"
  else
    combi="${combi} $ouf"
  fi
done

echo "## combining ..."
ecf=$mdir/EcoIndex_${nam}_${obs}_${spc}_${fcs}.nc
CDO $combi $ecf

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
