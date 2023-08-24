#!/bin/bash
{
startTime=$(date +"%s" -u)
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

## Set inputs
nam=$1 #MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6
frq=fx #day
fcs=$4 #1995-2014
din=$5 #data/RCMs/$nam
v=popdenmean

## Start processing
dpd=$din/../GPWv4
fin=$dpd/popden_gpwv4_5y_2000-2020.nc 

grid=$( eval ls $din/orog_*.nc | head -1 )
drp=$dpd/remap_$nam
frp=$drp/popden_GPWv4_5y_2000-2020.nc
mkdir -p $drp

dou=$din/index
mkdir -p $dou

fou=$dou/popden_${v}_${nam}.nc

echo "##########################################"
echo "## index = $idx($v) "
echo "## focus = $fcs"
echo "## data  = $nam"
echo "##########################################"

if [ ! -f $frp ]; then
  echo "preparing remap..."
  CDO remapdis,$grid $fin $frp
fi

echo preparing mean for 2000, 2005, 2010, 2015...
CDO timmean -seltimestep,1/4 $frp $fou
echo cleaning netcdf varnames...
cdo vardes $fou > varnames
cdo -f grb copy $fou test.grb
cdo -f nc setpartab,varnames test.grb test_new.nc
CDO chname,var1,$v test_new.nc test_new2.nc
rm varnames test.grb test_new.nc
mv test_new2.nc $fou
longname="Population Density, v4.11 (2000, 2005, 2010, 2015, 2020): 2.5 arc-minutes"
ncatted -O -a long_name,$v,a,c,"$longname" $fou
ncatted -O -a units,$v,a,c,"Persons per square kilometer" $fou
ncatted -O -a cell_methods,$v,a,c,"time: mean" $fou

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"


}
