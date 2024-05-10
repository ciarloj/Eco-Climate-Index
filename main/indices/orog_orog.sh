#!/bin/bash
{
startTime=$(date +"%s" -u)
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

## Set inputs
nam=$1 #MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6
frq=fx #day
yrs=$3 #1970-2005
fcs=$4 #1986-2005
din=$5 #data/RCMs/$nam

## Start processing
dou=$din/index
mkdir -p $dou

# orography
v=orog
idx=orog
fin=$din/${v}_${nam}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${nam}_${yrs}.nc
if [ ! -f $fin ]; then
  fin=$din/${v}_${nam}_${frq}.nc
  fou=$dou/${v}_${idx}_${nam}.nc
fi

echo "##########################################"
echo "## index = $idx($v) "
echo "## data  = $nam"
echo "##########################################"

cp $fin $fou

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"


}
