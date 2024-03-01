#!/bin/bash
{
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
mdir=$hdir/tools/missed/logs

dnam=EOBS-010-v25e
onam=iNaturalist
varlist="cdd rx1day prsum cwfi hwfi tasmean windmean orog"
spclist="ameles-decolor argiope-lobata brachytrupes-megacephalus polyommatus-celina scarabaeus-variolosus selysiothemis-nigra spilostethus-pandurus xylocopa-violacea"

[[ $dnam = ECMWF-ERAINT_r1i1p1_EUR-11-ens-6 ]] && dtyp=RCMs && yrs=1980-2010
[[ $dnam = EOBS-010-v25e ]] && dtyp=OBS && yrs=1980-2010

for spc in $spclist; do

  echo "checking $spc ..."
  nobs=$( cat $hdir/data/OBS/$onam/${spc}_${onam}.csv | wc -l )
  ntrg=5000 # target number of observations (to reach with boot if required)
  nboot=$( echo "scale=4; $ntrg / $nobs" | bc )
  nboot=$( printf "%.0f\n" "$nboot" ) #round
  [[ $nboot -lt 1 ]] && nboot=1

  mlogf=$mdir/missed.${spc}.log
  nmis=$( cat $mlogf | wc -l )
  ologf=$mdir/missed.${onam}.${dnam}.${yrs}.${spc}.log
 
  for n in $( seq 1 $nmis ); do
    [[ $n -eq $nmis ]] && break
    [[ $n -eq 1 ]] && echo "lat lon EI $varlist" > $ologf
    [[ $n -le 3 ]] && continue

    echo checking latlon $n/$nmis ...
    set +e
    ievl=$( cat $mlogf | head -$n | tail -1 | cut -d' ' -f2 )
    ilat=$( cat $mlogf | head -$n | tail -1 | cut -d' ' -f3 )
    ilon=$( cat $mlogf | head -$n | tail -1 | cut -d' ' -f4 )
    set -e

    ddir=$hdir/data/$dtyp/$dnam/index/$onam/boot_${nboot}/ndis
    ivals=""
    for v in $varlist ; do
      vfil=$ddir/${v}_${dnam}_${onam}_${spc}_${yrs}.nc
      vfll=$mdir/${v}.missed.${onam}.${dnam}.${yrs}.${spc}.nc
      CDO remapnn,lon=${ilon}_lat=${ilat} $vfil $vfll >/dev/null
      val=$( ncdump -v comp $vfll | tail -2 | head -1 | cut -d'=' -f2 | cut -d' ' -f3 )
      ivals="$ivals $val"
      rm $vfll
    done
    echo "$ilat $ilon $ievl $ivals" >> $ologf

  done
done

echo script done.

}
