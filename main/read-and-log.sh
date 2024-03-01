#!/bin/bash
#SBATCH -J read-and-log
#SBATCH -o logs/read-and-log.o
#SBATCH -e logs/read-and-log.e
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
nam=$2 #EOBS-010-v25e
# [ $nam = EOBS-010-v25e ]; then
dat=$3 #OBS
fcs=$4 #1995-2014
vars=$5 #"pr tas tasmax tasmin sfcWind orog"

ddir=data/$dat/$nam

ocsv=$1   ## path to inaturalist csv file
spc=$( basename $ocsv | cut -d_ -f1 )
#if [ $# -ne 1 ]; then
#   echo "Please provide CSV file name"
#   echo "Example: $0 data/OBS/iNaturalist/apis-mellifera_iNaturalist_eur.csv"
#   exit 1
#fi
if [ ! -f $ocsv ]; then
  echo 'Missing obs file: '$csv
  exit -1
fi
obs=$( basename $( dirname $ocsv ))

## Start processing
idir=$ddir/index/
odir=$idir/$obs
lout=$odir/$( basename $ocsv .csv )_${nam}.log
mkdir -p $odir

echo "##########################################"
echo "## obs   = $( basename $ocsv .csv )"
echo "## data  = $nam"
echo "##########################################"

header="# lat lon"
v_pr="cdd rx1day prsum" #"r99 r10mm r20mm rx5day nrx5day"
v_ts="tasmean cwfi hwfi" #"tasp90 tasp10 tx90p tx10p" 
v_tx="tasmaxmax tasmaxmean"
v_tn="tasminmin tasminmean"
v_mr="mrsomean"
v_wd="windmean" #fg6bft
v_og="orog"
v_po="popdenmean"

i=0
while read line; do
  i=$(( $i + 1 ))
  [[ $i = 1 ]] && continue
  lat=$( echo $line | cut -d, -f9 )
  [[ -z $lat ]] && continue
  lon=$( echo $line | cut -d, -f10 )
  [[ -z $lon ]] && continue
  #echo "## Processing $lat $lon ##"
  entry="$(( $i-1 )) $lat $lon "
  for v in $vars; do
    [[ $v = pr      ]] && indices="$v_pr"
    [[ $v = tas     ]] && indices="$v_ts"
    [[ $v = tasmax  ]] && indices="$v_tx"
    [[ $v = tasmin  ]] && indices="$v_tn"
    [[ $v = mrso    ]] && indices="$v_mr"
    [[ $v = sfcWind ]] && indices="$v_wd"
    [[ $v = orog    ]] && indices="$v_og"
    [[ $v = popden  ]] && indices="$v_po"
    for id in $indices; do
      header="$header $id"
      #echo "## extracting $id from $v .."
      idxf=$idir/${v}_${id}_${nam}_${fcs}.nc
      [[ $id = orog ]] && idxf=$idir/${v}_${id}_${nam}.nc
      [[ $id = popdenmean ]] && idxf=$idir/${v}_${id}_${nam}.nc
      tmpf=$idir/.${v}_${id}_${nam}_${fcs}_${spc}_tmp.nc
      CDO remapnn,lon=$lon/lat=$lat $idxf $tmpf >/dev/null
      val=$( ncdump -v $id $tmpf | tail -2 | head -1 | cut -d' ' -f3 )
      rm $tmpf
      entry="$entry $val"
    done
  done
  [[ $i = 2 ]] && echo $header > $lout
  echo $entry >> $lout
  echo $entry
done < $ocsv

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
