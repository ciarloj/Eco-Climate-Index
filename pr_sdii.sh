#!/bin/bash
{
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

din=data
dou=indx
mkdir -p $dou

v=pr
rcm=EOBS
frq=day
yrs=2006-2021

# simple daily intensity index
# sum of pr(>1mm)/no of wet days
idx=sdii
fin=$din/${v}_${rcm}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${rcm}_${yrs}.nc

echo "###################"
echo "## index = $idx($v)"
echo "## model = $rcm"
echo "###################"
CDO chname,simple_daily_intensity_index_per_time_period,sdii -eca_sdii $fin $fou
echo "Done!"

}
