#!/bin/bash
{
set -eo pipefail
startTime=$(date +"%s" -u)
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

## Set inputs
nam=$1 #MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6
frq=$2 #day
yrs=$3 #1970-2005
fcs=$4 #1986-2005
din=$5 #data/RCMs/$nam

## Start processing
dou=$din/index
mkdir -p $dou

y1=$( echo $fcs | cut -d- -f1 )
y2=$( echo $fcs | cut -d- -f2 )
dy=$(( $y2 - $y1 + 1 ))

# mean of yearly precipitation sum 
v=pr
idx=prsum 
fin=$din/${v}_${nam}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${nam}_${fcs}.nc

echo "##########################################"
echo "## index = $idx($v)"
echo "## data  = $nam"
echo "##########################################"

#CDO chname,$v,$idx -timmean -yearsum -mulc,86400 -selyear,$y1/$y2 $fin $fou
if [ $fcs -eq $yrs ]; then
  CDO chname,$v,$idx -timmean -yearsum $fin $fou
else
  CDO chname,$v,$idx -timmean -yearsum -selyear,$y1/$y2 $fin $fou
fi
ncatted -O -a units,$idx,m,c,"mm/year" $fou

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"


}
