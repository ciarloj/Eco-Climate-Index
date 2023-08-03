#!/bin/bash
{
set -eo pipefail
startTime=$(date +"%s" -u)
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

## Set inputs
rcm=MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6
yrs=1970-2005
din=data/RCMs/$rcm

## Set analysis conditions
frq=day
fcs=1986-2005

## Start processing
dou=$din/index
mkdir -p $dou

y1=$( echo $fcs | cut -d- -f1 )
y2=$( echo $fcs | cut -d- -f2 )
dy=$(( $y2 - $y1 + 1 ))

# Annual mean of Total Soil Moisture Conent
v=mrso
idx=mrsomean
fin=$din/${v}_${rcm}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${rcm}_${fcs}.nc

echo "##########################################"
echo "## index = $idx($v)"
echo "## model = $rcm"
echo "##########################################"
dsy=$din/.sy_${idx}
mkdir -p $dsy
ftm=$dsy/$( basename $fin .nc )_sy.nc

CDO selyear,$y1/$y2 $fin $ftm
CDO chname,$v,$idx -timmean $ftm $fou
ncatted -O -a long_name,$idx,m,c,"yearly_soil_moisture_content" $fou
ncatted -O -a standard_name,$idx,m,c,"Yearly Mean Total Soil Moisture Content" $fou
ncatted -O -a units,$idx,m,c,"kg m-2 year-1" $fou
rm $ftm
rmdir $dsy

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"


}
