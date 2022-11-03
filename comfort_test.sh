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

# simple daily intensity index
# sum of pr(>1mm)/no of wet days
idx=sdii
fin=$dou/${v}_${idx}_${rcm}_${yrs}.nc
fou=$dou/C_${idx}_${rcm}_${yrs}.nc

if [ $idx = sdii ]; then
  avg=7.106806632
  sdv=2.147072988
  lim=1.367769353
elif [ $idx = cdd ]; then
  avg=57.92652068
  sdv=37.00567862
  lim=7.27521724
fi


echo "###################"
echo "## index = $idx($v)"
echo "## model = $rcm    "
echo "###################"
CDO chname,$idx,C -setrtoc,-inf,0,0 -addc,1 -mulc,-1 -abs -divc,$lim -divc,$sdv -subc,$avg $fin $fou
echo "Done!"

}
