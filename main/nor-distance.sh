#!/bin/bash
#SBATCH -J nor-distance
#SBATCH -o logs/mah.o
#SBATCH -e logs/mah.e
#SBATCH -t 24:00:00
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jciarlo@ictp.it
#SBATCH -p esp
{
set -eo pipefail
startTime=$(date +"%s" -u)
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

export spc=$3 #xylocopa-violacea   
export obs=$2 #iNaturalist
export nam=$1 #EOBS-010-v25e
nboot=$4 #1 #5000  # number of bootstap replications

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
dat=$5 #OBS
fcs=$6 #1995-2014

idir=data/$dat/$nam/index
odir=$idir/$obs
ndir=$idir/$obs/boot_${nboot}/
mdir=$ndir/ndis
mkdir -p $mdir
script=$hdir/tools/stats.ncl

echo "##########################################"
echo "## spc   = $spc"
echo "## obs   = $obs"
echo "## model = $nam"
echo "##########################################"

olog=$odir/${spc}_${obs}_${nam}.log #original observations
flog=$ndir/${spc}_${obs}_${nam}.csv #bootstrapped observations
elog=$mdir/${spc}_${obs}_${nam}_${fcs}.ecolog #store stats for historical
echo "" > $elog

export scrf=$flog
cols=$( head -1 $flog )
vars=$( head -1 $flog | cut -d' ' -f4- )
nv=0
for v in $vars; do
  nv=$(( $nv + 1 ))
done
export ncomp=$nv

c=0
combi=""
for v in $vars; do
  c=$(( $c + 1 ))
  echo "--- $v ---"
  vc=0
  for vo in $cols; do
    vc=$(( $vc + 1 ))
    [[ $vo = $v ]] && break
  done
  export cn=$(( $vc - 1 ))

  stt=$( ncl -nQ $script )
  avg=$( echo $stt | cut -d, -f2 )
  std=$( echo $stt | cut -d, -f1 )
  lim=$( echo $stt | cut -d, -f3 )

  echo "## $v($cn) avg=$avg std=$std lim=$lim ##"
  echo "## $v($cn) avg=$avg std=$std lim=$lim ##" >> $elog
  if [ $v = orog -o $v = popdenmean ]; then
    vif=$( eval ls $idir/*_${v}_${nam}.nc )
  else
    vif=$( eval ls $idir/*_${v}_${nam}_${fcs}.nc )
  fi
  ouf=$mdir/${v}_${nam}_${obs}_${spc}_${fcs}.nc
  set0="setmissval,-9999 -setrtoc,-inf,0,0 -chname,$v,comp"
  CDO $set0 -addc,1 -mulc,-1 -divc,$lim -abs -divc,$std -subc,$avg $vif $ouf

  if [ $c -lt $ncomp ]; then
    [[ $c = 1 ]] && combi="$combi mul $ouf" || combi="${combi} -mul $ouf"
  else
    combi="${combi} $ouf"
  fi
done

echo "## combining ..."
ecf=$mdir/EcoIndex_${nam}_${obs}_${spc}_${fcs}.nc
#echo "CDO $combi $ecf"
CDO $combi $ecf

#find historical max at lat/lon of observations
nobs=$( cat $olog | wc -l )
ecoll=$mdir/EcoIndex_${nam}_${obs}_${spc}_${fcs}_ll.nc
ecomx=$mdir/EcoIndex_${nam}_${obs}_${spc}_${fcs}_max.nc
tmp=$mdir/EcoIndex_${nam}_${obs}_${spc}_${fcs}_tmp.nc
for n in $( seq 2 $nobs ); do # start from 2 to skip header
  echo "##finding max for obs $(( n-1 )) / $(( $nobs -1 ))"
  set +e
  line=$( cat $olog | head -$n | tail -1 )
  set -e
  lat=$( echo $line | cut -d' ' -f2 )
  lon=$( echo $line | cut -d' ' -f3 )
  CDO remapnn,lon=${lon}_lat=${lat} $ecf $ecoll 2>/dev/null
  if [ $n = 2 ]; then
    cp $ecoll $ecomx
  else
    CDO ensmax $ecoll $ecomx $tmp 2>/dev/null
    mv $tmp $ecomx
  fi
done
rm $ecoll
set +e 
emx=$( ncdump -v comp $ecomx | tail -2 | head -1 | cut -d' ' -f3 ) 
set -e
rm $ecomx
echo "## Emax = $emx"
echo "## Emax = $emx" >> $elog
CDO divc,$emx $ecf $tmp 
mv $tmp $ecf

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
