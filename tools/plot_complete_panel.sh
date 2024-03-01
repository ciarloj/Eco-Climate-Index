#!/bin/bash
{
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

export hdir=/home/netapp-clima-scratch/jciarlo/paleosim
export dnam=EOBS-010-v25e
export dnam=ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0-BATS_CP
#export dnam=ECMWF-ERAINT_r1i1p1_EUR-11-ens-6
export onam=iNaturalist
spclist="ameles-decolor argiope-lobata brachytrupes-megacephalus polyommatus-celina scarabaeus-variolosus selysiothemis-nigra spilostethus-pandurus xylocopa-violacea"

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

  echo "preparing for $spc ..."
  nobs=$( cat $hdir/data/OBS/$onam/${spc}_${onam}.csv | wc -l )
  ntrg=5000 # target number of observations (to reach with boot if required)
  nboot=$( echo "scale=4; $ntrg / $nobs" | bc )
  nboot=$( printf "%.0f\n" "$nboot" ) #round
  [[ $nboot -lt 1 ]] && nboot=1
  export nboot=$nboot
  export spc=$spc

  export bnam="_${dnam}_${onam}_${spc}_${yrs}.nc"
  export edir=$hdir/data/$dtyp/$dnam/index/$onam/boot_$nboot/ndis
  efil=$edir/EcoIndex_${dnam}_${onam}_${spc}_${yrs}.nc

  ldir=$hdir/data/$dtyp/$dnam/index/$onam
  lfil=$ldir/${spc}_${onam}_${dnam}.log
  export slog=$lfil
  nobs=$( cat $lfil | wc -l )

  eldir=$edir/latlon
  ellog=$eldir/EcoIndex_${dnam}_${onam}_${spc}_${yrs}.log
  mkdir -p $eldir
  if [ ! -f $ellog ]; then
  for n in $( seq 1 $nobs ); do
    [[ $n -eq $nobs ]] && echo -n -e "\r\e[0K" && break
    [[ $n -eq 1 ]] && echo "#EI" > $ellog
    elfil=$eldir/$( basename $efil .nc )_ll${n}.nc
  #  [[ -f $elfil ]] && continue
    echo -n -e "\rchecking latlon $n/$nobs ..."
    nn=$(( n + 1 ))
    set +e
    ilat=$( cat $lfil | head -$nn | tail -1 | cut -d' ' -f2 ) 
    ilon=$( cat $lfil | head -$nn | tail -1 | cut -d' ' -f3 )
    set -e
    CDO remapnn,lon=${ilon}_lat=${ilat} $efil $elfil >/dev/null
    val=$( ncdump -v comp $elfil | tail -2 | head -1 | cut -d'=' -f2 | cut -d' ' -f3 )
    rm $elfil
    echo $val >> $ellog 
  done
  fi

  ncl -Q tools/plot_complete_panel.ncl | grep -v 'warning:ContourPlot'

done

}
