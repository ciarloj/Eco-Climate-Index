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

# consecutive dry days 
# largest number 
idx=cdd
fin=$din/${v}_${rcm}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${rcm}_${yrs}.nc

echo "###################"
echo "## index = $idx($v)"
echo "## model = $rcm"
echo "###################"
CDO -chname,consecutive_dry_days_index_per_time_period,cdd -selvar,consecutive_dry_days_index_per_time_period -eca_cdd $fin $fou
echo "Done!"

}
