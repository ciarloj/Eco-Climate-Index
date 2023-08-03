#!/bin/bash
{
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

din=data
dou=indx
mkdir -p $dou

v=tas
rcm=MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6
frq=day
yrs=1970-2005
fcs=1986-2005
y1=$( echo $fcs | cut -d- -f1 )
y2=$( echo $fcs | cut -d- -f2 )
dy=$(( $y2 - $y1 + 1 ))

# simple daily intensity index
# sum of pr(>1mm)/no of wet days
idx=tg10p
fin=$din/${v}_${rcm}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${rcm}_${fcs}.nc

echo "###################"
echo "## index = $idx($v) "
echo "## model = $rcm"
echo "###################"

rr=10
ftm=${fin}_sy.nc
frr=${fou}_${rr}.nc
CDO selyear,$y1/$y2 $fin $ftm
CDO timselpctl,$rr,$dy $ftm -timselmin,5 $ftm -timselmax,5 $ftm $frr
CDO eca_tg10p $ftm $frr $fou
exit 
CDO chname,$v,$idx -eca_tg10p $ftm $frr $fou
rm $frr $ftm

echo "Done!"

}
