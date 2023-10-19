#!/bin/bash
{
set -eo pipefail

nam=ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0_CP
obs=iNaturalist
spc=$1 #xylocopa-violacea

if [ $nam = MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6 ]; then
  dat=RCMs
  yrs=1970-2005
  fcs=1986-2005
  vars="pr tas mrso sfcWind orog"
  echo $nam needs some script updates
  exit 1
elif [ $nam = ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0_CP ]; then
  dat=CPMs
  yrs=1995-1999
  fcs=$yrs
  vars="pr tas sfcWind orog"
elif [ $nam = EOBS-010-v25e ]; then
  dat=OBS
  yrs=1985-2021
  fcs=1995-2014
# vars="pr tas tasmax tasmin sfcWind orog popden"
# vars="pr tas sfcWind orog popden" 
  vars="pr tas sfcWind orog"
fi

nobs=$( cat data/OBS/$obs/${spc}_${obs}.csv | wc -l )
ntrg=5000 # target number of observations (to reach with boot if required)
nboot=$( echo "scale=4; $ntrg / $nobs" | bc ) 
nboot=$( printf "%.0f\n" "$nboot" ) #round
[[ $nboot -lt 1 ]] && nboot=1

echo "Select processes to run:"
echo "  indices read boot pca mah ndis"
read -p "Your selection:" sel
if [ $sel != "indices" -a $sel != "read" -a $sel != "boot" -a $sel != "pca" -a $sel != "mah" -a $sel != "ndis" ]; then
  echo "Incorrect Selection: $sel - must be indices, read, boot, pca, mah, or ndis"
  exit 1
fi

if [ $sel = indices ]; then
  echo "## Running Climate indices..."
  bash main/run_all_indices.sh $nam $dat $yrs $fcs "$vars"
fi

if [ $sel = read ]; then
  echo "running read-and-log..."
  bash main/submit_read-and-log.sh $nam $obs $spc $dat $fcs "$vars"
fi

if [ $sel = boot ]; then
  echo "running bootstrap..."
  bash main/bootstrapping.sh $nam $obs $spc $nboot $dat $fcs
fi

if [ $sel = pca ]; then
  echo "running pca..."
  bash main/pca.sh $nam $obs $spc $nboot $dat $fcs
fi

if [ $sel = mah ]; then
  echo "running mahalonobis..."
  bash main/mahalonobis.sh $nam $obs $spc $nboot $dat $fcs
fi

if [ $sel = ndis ]; then
  echo "running nor-distance..."
  bash main/nor-distance.sh $nam $obs $spc $nboot $dat $fcs
fi
  
echo "done."
}
