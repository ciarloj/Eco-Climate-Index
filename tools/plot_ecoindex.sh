#!/bin/bash
{
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

export hdir=/home/netapp-clima-scratch/jciarlo/paleosim
export dnam=EOBS-010-v25e
export onam=iNaturalist
export spc=$1

export dp=summary
if [ $dnam = ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0_CP ]; then
  export dtyp=CPMs
  export yrs=1995-1999
  export tdim=2d
elif [ $dnam = EOBS-010-v25e ]; then
  export dtyp=OBS
  export yrs=1980-2010
  export tdim=1d
fi

nobs=$( cat $hdir/data/OBS/$onam/${spc}_${onam}.csv | wc -l )
ntrg=5000 # target number of observations (to reach with boot if required)
nboot=$( echo "scale=4; $ntrg / $nobs" | bc )
nboot=$( printf "%.0f\n" "$nboot" ) #round
[[ $nboot -lt 1 ]] && nboot=1
export nboot=$nboot

edir=$hdir/data/$dtyp/$dnam/index/$onam/boot_$nboot/ndis
efil=$edir/EcoIndex_${dnam}_${onam}_${spc}_${yrs}.nc

ldir=$hdir/data/$dtyp/$dnam/index/$onam
lfil=$ldir/${spc}_${onam}_${dnam}.log

eldir=$edir/latlon
ellog=$eldir/EcoIndex_${dnam}_${onam}_${spc}_${yrs}.log
mkdir -p $eldir
if [ $dp = true ]; then
if [ ! -f $ellog ]; then
for n in $( seq 1 $nobs ); do
  [[ $n -eq 1 ]] && echo "#EI" > $ellog
  elfil=$eldir/$( basename $efil .nc )_ll${n}.nc
#  [[ -f $elfil ]] && continue
  echo checking latlon $n/$nobs ... 
  nn=$(( n + 1 ))
  set +e
  ilat=$( cat $lfil | head -$nn | tail -1 | cut -d' ' -f2 ) 
  ilon=$( cat $lfil | head -$nn | tail -1 | cut -d' ' -f3 )
  set -e
  CDO remapnn,lon=${ilon}_lat=${ilat} $efil $elfil
  val=$( ncdump -v comp $elfil | tail -2 | head -1 | cut -d'=' -f2 | cut -d' ' -f3 )
  echo $val >> $ellog 
done
fi
fi

ncl -Q tools/plot_ecoindex.ncl | grep -v 'warning:stringtofloat'



}
