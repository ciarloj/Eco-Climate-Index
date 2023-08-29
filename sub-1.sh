#!/bin/bash
{
set -eo pipefail

nam=EOBS-010-v25e
obs=iNaturalist
spc=xylocopa-violacea

if [ $nam = MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6 ]; then
  dat=RCMs
  yrs=1970-2005
  fcs=1986-2005
  vars="pr tas mrso sfcWind orog"
  echo $nam needs some script updates
  exit 1
elif [ $nam = EOBS-010-v25e ]; then
  dat=OBS
  yrs=1985-2021
  fcs=1995-2014
  vars="pr tas tasmax tasmin sfcWind orog popden"
fi

nobs=$( cat data/OBS/$obs/${spc}_${obs}.csv | wc -l )
if [ $nobs -ge 1000 ]; then
  nboot=1
elif [ $nobs -lt 1000 -a $nobs -ge 500 ]; then
  nboot=1000
else
  nboot=5000
fi 

scr=$1



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
  slrm="-J $j -o $o -e $e"
  jidb=$( sbatch $slrm main/bootstrapping.sh $nam $obs $spc $nboot $dat $fcs | cut -d' ' -f4 )
fi

if [ $scr = main/pca.sh ]; then
  echo "submitting pca..."
  j="pca_${spc}_${nam}"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e"
  jidp=$( eval sbatch $slrm main/pca.sh $nam $obs $spc $nboot $dat $fcs | cut -d' ' -f4 )
fi

if [ $scr = main/mahalonobis.sh ]; then
  echo "submitting mahalonobis..."
  j="mah_${spc}_${nam}"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e -d afterok:$jidp"
  jidl=$( eval sbatch $slrm main/mahalonobis.sh $nam $obs $spc $nboot $dat $fcs )
fi  

echo "done."
}
