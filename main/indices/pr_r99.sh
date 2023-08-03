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
idx=r99
fin=$din/${v}_${nam}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${nam}_${fcs}.nc
rr=$( echo $idx | cut -c2- )

echo "##########################################"
echo "## index = $idx($v)"
echo "## data  = $nam"
echo "##########################################"
dsy=$din/.sy_${idx}
dpp=$din/p$rr
mkdir -p $dsy $dpp
ftm=$dsy/$( basename $fin .nc )_sy.nc
frr=$dpp/${v}_${nam}_${frq}_${fcs}_p${rr}.nc
frx=$dpp/${v}_${nam}_${frq}_${fcs}_max.nx
frn=$dpp/${v}_${nam}_${frq}_${fcs}_min.nc

#CDO mulc,86400 -selyear,$y1/$y2 $fin $ftm
set -xe
CDO selyear,$y1/$y2 $fin $ftm
CDO timmax $ftm $frx
CDO timmin $ftm $frn
[[ ! -f $frr ]] && CDO timpctl,$rr $ftm $frn $frx $frr
CDO chname,$v,$idx -divc,$dy -timsum -mul $ftm -ge $ftm $frr $fou
ncatted -O -a long_name,$idx,m,c,"total_precipitation_ge_p$rr" $fou
ncatted -O -a standard_name,$idx,m,c,"Yearly Mean Total Extreme(>/=P$rr) Precipitation" $fou
ncatted -O -a units,$idx,m,c,"mm/year" $fou
rm $ftm $frn $frx
rmdir $dsy

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"


}
