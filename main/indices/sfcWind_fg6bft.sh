#!/bin/bash
{
startTime=$(date +"%s" -u)
set -eo pipefail
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

# number of days with averaged wind above 10.8m/s
# number of days woth FG>=6 Bft (10.8m/s)
# https://www.rdocumentation.org/packages/ClimInd/versions/0.1-3/topics/fg6bft
# https://www.ecad.eu//indicesextremes/indicesdictionary.php#9
v=sfcWind
idx=fg6bft
fin=$din/${v}_${nam}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${nam}_${fcs}.nc

echo "##########################################"
echo "## index = $idx($v) "
echo "## data  = $nam"
echo "##########################################"
dsy=$din/.sy_${idx}_$fcs
mkdir -p $dsy
ftm=$dsy/$( basename $fin .nc )_sy.nc

if [ $fcs != $yrs ]; then
  CDO selyear,$y1/$y2 $fin $ftm
else
  ftm=$fin
fi
CDO chname,$v,$idx -divc,$dy -timsum -gec,10.8 $ftm $fou
ncatted -O -a long_name,$idx,m,c,"days_above_6Bft" $fou
ncatted -O -a standard_name,$idx,m,c,"Yearly Mean days with wind speed >/= 6Bft" $fou
ncatted -O -a units,$idx,m,c,"days/year" $fou
if [ $fcs != $yrs ]; then
  rm $ftm
  rmdir $dsy
fi

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"


}
