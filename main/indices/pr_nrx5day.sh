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

# extreme wet day precipitation (mm)
# total precipitation above (inclusive) P99
v=pr
vn=number_of_5day_heavy_precipitation_periods_per_time_period
idx=nrx5day
fin=$din/${v}_${nam}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${nam}_${fcs}.nc
rr=$( echo $idx | cut -c2- )

echo "##########################################"
echo "## index = $idx($v)"
echo "## data  = $nam"
echo "##########################################"

ftm=$fin
if [ $yrs != $fcs ]; then
  dsy=$din/.sy_${idx}
  mkdir -p $dsy
  ftm=$dsy/$( basename $fin .nc )_sy.nc
  CDO selyear,$y1/$y2 $fin $ftm
fi

#CDO mulc,86400 -selyear,$y1/$y2 $fin $ftm
set -e
CDO chname,$vn,$idx -selvar,$vn -divc,$dy -eca_rx5day -runsum,5 $ftm $fou
ncatted -O -a long_name,$idx,m,c,"number_of_5day_heavy_precipitation_periods_per_year" $fou
ncatted -O -a standard_name,$idx,m,c,"Number of 5day Precipitation Periods per year" $fou
ncatted -O -a units,$idx,m,c,"days/year" $fou

[[ $yrs != $fcs ]] && rm $ftm
[[ $yrs != $fcs ]] && rmdir $dsy

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"


}
