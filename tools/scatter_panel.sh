#!/bin/bash
{
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
export dnam=ECMWF-ERAINT_r1i1p1_EUR-11-ens-6
export onam=iNaturalist
export odir=$hdir/images
mkdir -p $odir

spclist="ameles-decolor argiope-lobata brachytrupes-megacephalus polyommatus-celina scarabaeus-variolosus selysiothemis-nigra spilostethus-pandurus xylocopa-violacea"

[[ $dnam = ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0_CP ]] && export dtyp=CPMs
[[ $dnam = ECMWF-ERAINT_r1i1p1_EUR-11-ens-6     ]] && export dtyp=RCMs
[[ $dnam = EOBS-010-v25e                        ]] && export dtyp=OBS

for spc in $spclist; do 

  export spc=$spc
  nobs=$( cat $hdir/data/OBS/$onam/${spc}_${onam}.csv | wc -l )
  ntrg=5000 # target number of observations (to reach with boot if required)
  nboot=$( echo "scale=4; $ntrg / $nobs" | bc )
  nboot=$( printf "%.0f\n" "$nboot" ) #round
  [[ $nboot -lt 1 ]] && nboot=1

  export flog=$hdir/data/$dtyp/$dnam/index/$onam/${spc}_${onam}_${dnam}.log
# export flog=$hdir/data/$dtyp/$dnam/index/$onam/boot_$nboot/${spc}_${onam}_${dnam}.csv
  ncl -Q $hdir/tools/scatter_panel.ncl | grep -v 'warning:tofloat: A bad value'

done

}
