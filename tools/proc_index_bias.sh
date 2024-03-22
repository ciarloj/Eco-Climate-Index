#!/bin/bash
{
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}
export hdir=/home/netapp-clima-scratch/jciarlo/paleosim

ref=EOBS-010-v25e
rtyp=OBS
rdir=data/$rtyp/$ref/index

nam=ECMWF-ERAINT_r1i1p1_EUR-11-ens-6
#nam=ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0-BATS_CP
[[ $nam = ECMWF-ERAINT_r1i1p1_EUR-11-ens-6 ]] && fcs=1980-2010 && dat=RCMs
[[ $nam = ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0-BATS_CP ]] && fcs=1995-2004 && dat=CPMs
ddir=data/$dat/$nam/index
bdir=$ddir/bias
mkdir -p $bdir

export indices="cdd prsum rx1day cwfi tasmean hwfi windmean orog"
varlist=""
for idx in $indices; do
  [[ $idx = cdd      ]] && varlist="$varlist pr"
  [[ $idx = prsum    ]] && varlist="$varlist pr"
  [[ $idx = rx1day   ]] && varlist="$varlist pr"
  [[ $idx = cwfi     ]] && varlist="$varlist tas"
  [[ $idx = tasmean  ]] && varlist="$varlist tas"
  [[ $idx = hwfi     ]] && varlist="$varlist tas"
  [[ $idx = windmean ]] && varlist="$varlist sfcWind"
  [[ $idx = orog     ]] && varlist="$varlist orog"
  echo "processing $idx ..."
  tsf=_${fcs}
  [[ $idx = orog ]] && tsf=""
  rf=$( ls $rdir/*_${idx}_${ref}${tsf}.nc )
  df=$( ls $ddir/*_${idx}_${nam}${tsf}.nc )
  gf=$bdir/$( basename $df .nc )_remap.nc
  bf=$bdir/$( basename $df )
  rmpt=dis
  [[ $idx = rx1day ]] && rmpt=nn
  [[ $idx = cwfi   ]] && rmpt=nn
  [[ $idx = hwfi   ]] && rmpt=nn
  if [ ! -f $bf ]; then
    CDO remap$rmpt,$rf $df $gf
    CDO div -sub $gf $rf $rf $bf
    rm $gf
  fi
done

export dtyp=$dat
export dnam=$nam
export yrs=$fcs
export varlist=$varlist
ncl -Q tools/plot_index_bias.ncl

echo "done."

}
