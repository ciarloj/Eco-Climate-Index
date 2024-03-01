#!/bin/bash
{
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

export hdir=/home/netapp-clima-scratch/jciarlo/paleosim
export dnam=EOBS-010-v25e
export dnam=ECMWF-ERAINT_r1i1p1_EUR-11-ens-6
export onam=iNaturalist
spclist="brachytrupes-megacephalus spilostethus-pandurus"
spclist="ameles-decolor argiope-lobata brachytrupes-megacephalus polyommatus-celina scarabaeus-variolosus selysiothemis-nigra spilostethus-pandurus xylocopa-violacea"
#spclist="ameles-decolor argiope-lobata polyommatus-celina scarabaeus-variolosus selysiothemis-nigra xylocopa-violacea"

if [ $dnam = ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0_CP ]; then
  export dtyp=CPMs
  export yrs=1995-1999
  export tdim=2d
elif [ $dnam = ECMWF-ERAINT_r1i1p1_EUR-11-ens-6 ]; then
  export dtyp=RCMs
  export yrs=1980-2010
  export tdim=2d
elif [ $dnam = ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0-BATS_CP ]; then
  export dtyp=CPMs
  export yrs=1995-2004
  export tdim=2d
elif [ $dnam = EOBS-010-v25e ]; then
  export dtyp=OBS
  export yrs=1980-2010
  export tdim=1d
fi

for spc in $spclist; do 

  nobs=$( cat $hdir/data/OBS/$onam/${spc}_${onam}.csv | wc -l )
  ntrg=5000 # target number of observations (to reach with boot if required)
  nboot=$( echo "scale=4; $ntrg / $nobs" | bc )
  nboot=$( printf "%.0f\n" "$nboot" ) #round
  [[ $nboot -lt 1 ]] && nboot=1
  export nboot=$nboot
  export spc=$spc

  export slog=$hdir/data/$dtyp/$dnam/index/$onam/${spc}_${onam}_${dnam}.log
  export edir=$hdir/data/$dtyp/$dnam/index/$onam/boot_$nboot/ndis/
  export bnam="_${dnam}_${onam}_${spc}_${yrs}.nc"

  ncl -Q tools/plot_components_panel.ncl

done


}
