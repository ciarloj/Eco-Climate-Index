#!/bin/bash
{
CDO(){
  cdo -O -L -f nc4 -z zip $@
}

rcm=EOBS
frq=day
yrs=2006-2021

vars="pr"
vars_pr="sdii cdd"
dou=indx  #index dir
sdir=inat #inaturalist data dir
dsrc=$sdir/observations-265204_apis-mellifera-eur.csv
logf=log.out

i=0
echo "# lat lon $vars_pr " > $logf
while read line; do
  i=$(( $i + 1 ))
  [[ $i = 1 ]] && continue
  lat=$( echo $line | cut -d, -f9 )
  lon=$( echo $line | cut -d, -f10 )
  #echo "## Processing $lat $lon ##"
  entry="$(( $i-1 )) $lat $lon "
  for v in $vars; do
    [[ $v = pr ]] && indices="$vars_pr"
    for id in $indices; do
      #echo "## extracting $id from $v .."
      idxf=$dou/${v}_${id}_${rcm}_${yrs}.nc
      CDO remapnn,lon=$lon/lat=$lat $idxf tmp.nc >/dev/null
      val=$( ncdump -v $id tmp.nc | tail -2 | head -1 | cut -d' ' -f3 )
      rm tmp.nc
      entry="$entry $val"
    done
  done
  echo $entry >> $logf
  echo $entry
done < $dsrc

}
