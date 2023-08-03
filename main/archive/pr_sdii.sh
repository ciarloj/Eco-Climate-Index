#!/bin/bash
{
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

din=data
dou=indx
mkdir -p $dou

v=pr
rcm=MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6
frq=day
yrs=1970-2005
fcs=1986-2005
y1=$( echo $fcs | cut -d- -f1 )
y2=$( echo $fcs | cut -d- -f2 )
dy=$(( $y2 - $y1 + 1 ))

# simple daily intensity index
# sum of pr(>1mm)/no of wet days
idx=sdii
fin=$din/${v}_${rcm}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${rcm}_${fcs}.nc

echo "###################"
echo "## index = $idx($v)"
echo "## model = $rcm"
echo "###################"
vo=simple_daily_intensity_index_per_time_period
CDO chname,$vo,$idx -eca_sdii -mulc,86400 -selyear,$y1/$y2 $fin $fou
echo "Done!"

}
