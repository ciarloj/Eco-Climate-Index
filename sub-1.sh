#!/bin/bash
{
set -eo pipefail

nam=ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0_CP
obs=iNaturalist
spc=$2 #xylocopa-violacea

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

scr=$1
dep=$3


if [ $scr = main/run_all_indices.sh ]; then
  echo "## Running Climate indices..."
  bash main/run_all_indices.sh $nam $dat $yrs $fcs "$vars"
fi

if [ $scr = main/submit_read-and-log.sh ]; then
  echo "## Running Ecological Niche Model..."
  echo "submitting read-and-log..."
  jidrl=$( bash main/submit_read-and-log.sh $nam $obs $spc $dat $fcs "$vars" | tail -1 | cut -d' ' -f4 )
fi

if [ $scr = main/bootstrapping.sh ]; then
  echo "submitting bootstrap..."
  j="boot_${spc}_${nam}"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e $dep"
  jidb=$( sbatch $slrm main/bootstrapping.sh $nam $obs $spc $nboot $dat $fcs | cut -d' ' -f4 )
fi

if [ $scr = main/pca.sh ]; then
  echo "submitting pca..."
  j="pca_${spc}_${nam}"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e $dep"
  jidp=$( eval sbatch $slrm main/pca.sh $nam $obs $spc $nboot $dat $fcs | cut -d' ' -f4 )
fi

if [ $scr = main/mahalonobis.sh ]; then
  echo "submitting mahalonobis..."
  j="mah_${spc}_${nam}"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e $dep"
  jidl=$( eval sbatch $slrm main/mahalonobis.sh $nam $obs $spc $nboot $dat $fcs )
fi  

if [ $scr = main/nor-distance.sh ]; then
  echo "submitting nor-distance..."
  j="ndis_${spc}_${nam}"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e $dep"
  jidl=$( eval sbatch $slrm main/nor-distance.sh $nam $obs $spc $nboot $dat $fcs )
fi

echo "done."
}
