#!/bin/bash
{
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

din=data
dou=indx
mkdir -p $dou

v=mrso
rcm=MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6
frq=day
yrs=1970-2005
fcs=1986-2005
y1=$( echo $fcs | cut -d- -f1 )
y2=$( echo $fcs | cut -d- -f2 )
dy=$(( $y2 - $y1 + 1 ))

# Annual mean of Total Soil Moisture Conent

idx=mrso90p
fin=$din/${v}_${rcm}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${rcm}_${fcs}.nc

echo "###################"
echo "## index = $idx($v) "
echo "## model = $rcm"
echo "###################"

rr=90
ftm=${fin}_sy.nc
CDO selyear,$y1/$y2 $fin $ftm
CDO chname,$v,$idx -timpctl,$rr $ftm -timmin $ftm -timmax $ftm $fou
rm $ftm

echo "Done!"

}
