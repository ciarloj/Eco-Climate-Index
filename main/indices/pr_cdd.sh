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

# consecutive dry days 
# average yearly cdd
v=pr
idx=cdd
fin=$din/${v}_${nam}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${nam}_${fcs}.nc

echo "##########################################"
echo "## index = $idx($v)"
echo "## data  = $nam"
echo "##########################################"

vo=cddETCCDI
#CDO chname,$vo,$idx -timmean -selvar,$vo -etccdi_cdd -mulc,86400 -selyear,$y1/$y2 $fin $fou
if [ $fcs -eq $yrs ]; then
  CDO chname,$vo,$idx -timmean -selvar,$vo -etccdi_cdd $fin $fou
else
  CDO chname,$vo,$idx -timmean -selvar,$vo -etccdi_cdd -selyear,$y1/$y2 $fin $fou
fi
ncatted -O -a long_name,$idx,m,c,"yearly_mean_of_maximum_consecutive_dry_days" $fou
ncatted -O -a standard_name,$idx,m,c,"Yearly Mean of Max Consecutive Dry Days (<1mm, >/=5days)" $fou
ncatted -O -a units,$idx,m,c,"days/year" $fou

#vo=consecutive_dry_days_index_per_time_period
#CDO -divc,$dy -chname,$vo,$idx -selvar,$vo -eca_cdd,1,5,freq=year -mulc,86400 -selyear,$y1/$y2 $fin $fou
endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"


}
