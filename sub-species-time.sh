#!/bin/bash
{
set -eo pipefail

hfcs=1995-2004
dat=CPMs

obs=iNaturalist
spc=$1 #xylocopa-violacea
nam=MPI-M-MPI-ESM1-2-LR_r1i1p1f1_ICTP-RegCM5-0-BATS_CP
dep=$3 #optional dependency

tim=$2 #hist,1850,1000,midH,lgm,gwl15,gwl2,gwl3
tsup=_$tim
if [ $nam = ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0-BATS_CP -o $nam = MPI-M-MPI-ESM1-2-LR_r1i1p1f1_ICTP-RegCM5-0-BATS_CP ]; then
  dat=CPMs
  vars="pr tas sfcWind orog"
  [[ $tim = hist ]] && fcs=$hfcs
  [[ $tim = 1850 ]] && fcs=1850-1859
  [[ $tim = 1000 ]] && fcs=1000-1009
  [[ $tim = midH ]] && fcs=1241-1250
  [[ $tim = lgm  ]] && fcs=2090-2099
  yrs=$fcs
fi

nobs=$( cat data/OBS/$obs/${spc}_${obs}.csv | wc -l )
ntrg=5000 # target number of observations (to reach with boot if required)
nboot=$( echo "scale=4; $ntrg / $nobs" | bc ) 
nboot=$( printf "%.0f\n" "$nboot" ) #round
[[ $nboot -lt 1 ]] && nboot=1
nboot=1

am=auto
if [ $am = manual ]; then
  echo "Running script for:"
  echo "  climate data = $nam ($fcs)"
  echo "  species data = $obs"
  echo "  species      = $spc"
  echo "    with nboot = $nboot"
  echo ""
  echo "Select processes to run:"
  echo " - Run $nam indices preparations? [C]"
  echo " - Run $obs PCA ENM processes?    [P]"
  echo " - Run $obs classic ENM processes?[E]"
  read -p "Your selection:" sel
  if [ $sel != "C" -a $sel != "E" -a $sel != "P" ]; then
    echo "Incorrect Selection: $sel - must be C, P, or E"
    exit 1
  fi
else
  sel=E
fi


if [ $sel = C ]; then
  echo "## Running Climate indices..."
  bash main/run_all_indices.sh $nam $dat $yrs $fcs "$vars" $tim "$dep"
fi

if [ $sel = E ]; then
  echo "## Running Classic Ecological Niche Model..."
  if [ $tim = hist ]; then
    echo "submitting read-and-log..."
    jidrl=$( bash main/submit_read-and-log.sh $nam $obs $spc $dat $fcs "$vars" "$dep" $tim | tail -1 | cut -d' ' -f4 )
    echo "submitting bootstrap..."
    j="boot_${spc}_${nam}$tsup"
    o=logs/${j}.out
    e=logs/${j}.err
    slrm="-J $j -o $o -e $e"
    slrm="$slrm -d afterok:$jidrl"
#   slrm="$slrm $dep" 
    jidb=$( sbatch $slrm main/bootstrapping.sh $nam $obs $spc $nboot $dat $fcs $tim | cut -d' ' -f4 )
  fi

  echo "submitting nor-distance..."
  j="ndis_${spc}_${nam}$tsup"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e"
  [[ $tim = hist ]] && slrm="$slrm -d afterok:$jidb"
  jidl=$( eval sbatch $slrm main/nor-distance.sh $nam $obs $spc $nboot $dat $fcs $tim $hfcs )

  echo "done."
fi

}
