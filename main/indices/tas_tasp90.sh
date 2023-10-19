#!/bin/bash
#SBATCH -J tas_tasp90 
#SBATCH -o logs/tas_tasp90.o
#SBATCH -e logs/tas_tasp90.e
#SBATCH -t 24:00:00
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jciarlo@ictp.it
#SBATCH -p esp

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

# temperature mean 
v=tas
rr=90
idx=tasp$rr 
fin=$din/${v}_${nam}_${frq}_${yrs}.nc
fsy=$dou/${v}_${idx}_${nam}_${fcs}_sy.nc
fou=$dou/${v}_${idx}_${nam}_${fcs}.nc

echo "##########################################"
echo "## index = $idx($v)"
echo "## data  = $nam"
echo "##########################################"

CDO chname,$v,$idx -selyear,$y1/$y2 $fin $fsy
CDO timpctl,$rr $fsy -timmin $fsy -timmax $fsy $fou
rm $fsy
ncatted -O -a long_name,$idx,m,c,"p${rr}_air_temperature" $fou
ncatted -O -a standard_name,$idx,m,c,"P$rr of Near-Surface Air Temperature" $fou

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
