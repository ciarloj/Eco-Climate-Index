#!/bin/bash
{
set -eo pipefail
startTime=$(date +"%s" -u)
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

export spc=apis-mellifera  #-ligustica
export obs=iNaturalist
export nam=EOBS-010-v25e
stat=boot  ## boot or basic

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
if [ $nam = MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6 ]; then
  dat=RCMs
  fcs=1986-2005
elif [ $nam = EOBS-010-v25e ]; then
  dat=OBS
  fcs=1995-2014
  indices="orog cdd r99 fg6bft windmean hwfi"
indices=r99
fi
ddir=data/$dat/$nam
idir=$ddir/index/
[[ $stat = boot ]] && bdir="$stat/" || bdir=""
script=$hdir/tools/stats_${stat}.ncl

array=($indices)
nind=${#array[@]}

echo "##########################################"
echo "## spc   = $spc"
echo "## obs   = $obs"
echo "## model = $nam"
echo "##########################################"

evdir=$idir/${bdir}EcoV
eidir=$evdir/${bdir}EcoIndex
export flog=$( eval ls $idir/$obs/${spc}_${obs}_*_${nam}.log )
export odir=$idir/images
mkdir -p $odir $eidir

set0='-setmissval,-9999 -setrtoc,-inf,0,0'
combi=""
c=0
for id in $indices; do
  c=$(( c+1 ))
  echo "## $id ..."
  export indx=$id
  trm1='replacing with missing value'
  trm2='procedure was coerced to the appropriate type'
ncl -nQ $script | grep -v "$trm1" | grep -v "$trm2"
exit

  ncltxt=$( ncl -nQ $script | grep -v "$trm1" | grep -v "$trm2" )
  v_s=$( echo $ncltxt | cut -d, -f1 )
  v_u=$( echo $ncltxt | cut -d, -f2 )
  v_N=$( echo $ncltxt | cut -d, -f3 )
  if [ $stat = basic ]; then
    export imgf=$( echo $ncltxt | cut -d, -f4 )
    ncl -nQ $hdir/tools/trim_pdf.ncl
  fi

  [[ $id = cdd      ]] && v=pr
  [[ $id = r99      ]] && v=pr
  [[ $id = prsum    ]] && v=pr
  [[ $id = hwfi     ]] && v=tas
  [[ $id = cwfi     ]] && v=tas
  [[ $id = tasmaxmax  ]] && v=tasmax
  [[ $id = tasmaxmean ]] && v=tasmax
  [[ $id = tasminmean ]] && v=tasmin
  [[ $id = tasminmin  ]] && v=tasmin
  [[ $id = mrsomean ]] && v=mrso
  [[ $id = fg6bft   ]] && v=sfcWind
  [[ $id = windmean ]] && v=sfcWind
  [[ $id = orog     ]] && v=orog
  [[ $id = orog ]] && sffx="" || sffx="_$fcs"
  fin=$idir/${v}_${id}_${nam}${sffx}.nc
  fev=$evdir/${id}_${spc}_${obs}_${nam}.nc
  CDO chname,$id,EcoV $set0 -addc,1 -mulc,-1 -abs -divc,$v_N -divc,$v_s -subc,$v_u $fin $fev
  if [ $c -lt $nind ]; then
    [[ $c = 1 ]] && combi="$combi mul $fev" || combi="${combi} -mul $fev"
  else
    combi="${combi} $fev"
  fi
done 

echo "## combining ..."
#ecof=$eidir/EcoIndex-ocean_$sfx 
eclf=$eidir/EcoIndex_${spc}_${obs}_${nam}.nc
CDO $combi $eclf
#CDO ifthenelse -setmisstoc,1 -lec,-1 $fev5 $ecof -mul $fev5 $ecof $eclf

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
