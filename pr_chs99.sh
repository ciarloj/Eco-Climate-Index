#!/bin/bash
{
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

din=data
dou=indx
mkdir -p $dou

v=pr
rcm=MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-7
frq=day
yrs=1996-2005
y1=$( echo $yrs | cut -d- -f1 )
y2=$( echo $yrs | cut -d- -f2 )
dy=$(( $y2 - $y1 + 1 ))

# simple daily intensity index
# sum of pr(>1mm)/no of wet days
idx=chs99
fin=$din/${v}_${rcm}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${rcm}_${yrs}.nc
rr=$( echo $idx | cut -c4- )

echo "###################"
echo "## index = $idx($v) $rr"
echo "## model = $rcm"
echo "###################"
CDO timpctl,$rr $fin -timmin $fin -timmax $fin ${fou}_$rr.nc
CDO chname,$v,$idx -divc,$dy -timsum -mul $fin -ge $fin ${fou}_$rr.nc $fou
rm ${fou}_$rr.nc

echo "Done!"

}
