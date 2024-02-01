#!/bin/bash
#SBATCH -t 7:00:00
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jciarlo@ictp.it
#SBATCH -p long
{
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}
startTime=$(date +"%s" -u)

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
dat=RCMs
fcs=1980-2010

rlist="CLMcom-ETH-COSMO-crCLIM-v1-1 CNRM-ALADIN63 GERICS-REMO2015 ICTP-RegCM4-6 KNMI-RACMO22E SMHI-RCA4"
edriv="ECMWF-ERAINT_r1i1p1_"
ens=EUR-11-ens-6
enam=$edriv$ens

ddir=$hdir/data/$dat
edir=$ddir/$enam/index
mkdir -p $edir

ilist="cdd r99 prsum tasp90 tasp10 tasmean windmean orog"
ilist="r99"

for i in $ilist; do
  echo "make ensmean for $i ..."
  v=$i
  [[ $i = cdd ]] && v=pr
  [[ $i = r99 ]] && v=pr
  [[ $i = prsum    ]] && v=pr
  [[ $i = tasp90   ]] && v=tas
  [[ $i = tasp10   ]] && v=tas
  [[ $i = tasmean  ]] && v=tas
  [[ $i = windmean ]] && v=sfcWind
  ys=_$fcs
  [[ $i = orog ]] && ys=""

  files=""
  for mr in $rlist; do
    cf=$ddir/${edriv}${mr}/index/${v}_${i}_${edriv}${mr}${ys}.nc
    files="$files $cf"
  done

  ef=$edir/${v}_${i}_${enam}${ys}.nc
  CDO ensmean $files $ef

done

echo Script Complete.



# standardize actual data
echo "*** standardizing climate indices ***"

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
