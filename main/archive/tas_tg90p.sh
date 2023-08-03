#!/bin/bash
{
CDO(){
  cdo -O -L -f nc4 -z zip $@
}
set -eo pipefail

din=data
dou=indx
dpc=90pc
mkdir -p $dou $dpc

v=tas
rcm=MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6
frq=day
yrs=1970-2005
fcs=1986-2005
y1=$( echo $fcs | cut -d- -f1 )
y2=$( echo $fcs | cut -d- -f2 )
dy=$(( $y2 - $y1 + 1 ))

# warm days above 90th percentile 
# 90th percentile of 5-yearly day period
idx=tg90p
fin=$din/${v}_${rcm}_${frq}_${yrs}.nc
fpc=$dpc/${v}_${rcm}_${frq}_${fcs}.nc
fou=$dou/${v}_${idx}_${rcm}_${fcs}.nc

echo "###################"
echo "## index = $idx($v) "
echo "## model = $rcm"
echo "###################"

rr=90
for y in $( seq $y1 $y2 ); do
  echo "## preparing $y .."
  fyr=$dpc/${v}_${rcm}_${frq}_${y}.nc
  CDO selyear,$y $fin $fyr >/dev/null
  set +e
  d=$( ncdump -h $fyr | grep -i time | head -1 | cut -d'(' -f2 | cut -d' ' -f1 )
  set -e
  if [ $d != 360 -a $d != 365 -a $d != 366 ]; then
    echo "Calendar Error! d="$d
    exit 1
  fi
  if [ $d -gt 365 ]; then
    echo "trimming $y.."
    CDO delete,day=29,month=2 $fyr leap.nc >/dev/null
    mv leap.nc $fyr
    set +e
    d=$( ncdump -h $fyr | grep -i time | head -1 | cut -d'(' -f2 | cut -d' ' -f1 )
    set -e
  fi
  fny=$dpc/${v}_${rcm}_${frq}_${y}_${d}.nc
  mv $fyr $fny
  for t in $( seq -w 1 $d ); do
    echo -n -e "\r## extracting $t/$d .."
    fts=$dpc/${v}_${rcm}_${frq}_${y}_${d}_${t}.nc
    CDO seltimestep,$t $fny $fts >/dev/null
    [[ $t = $d ]] && echo -n -e "\r\e[0K"
  done
done
dn=$d
for n in $( seq -w 1 $dn ); do
  echo "## working on ts $n .."
  prf=$dpc/${v}_${rcm}_${frq}_????_${dn}_
  fda=$dpc/${v}_${rcm}_${frq}_${n}_data.nc
  fdm2=${prf}$(printf "%03d" $((10#$n-2))).nc
  fdm1=${prf}$(printf "%03d" $((10#$n-1))).nc
  fdn0=${prf}${n}.nc
  fdp1=${prf}$(printf "%03d" $((10#$n+1))).nc
  fdp2=${prf}$(printf "%03d" $((10#$n+2))).nc
  if [ $n -eq 1 ]; then
    fdm2=${prf}$(printf "%03d" $((10#$dn-1))).nc
    fdm1=${prf}${dn}.nc
  elif [ $n -eq 2 ]; then
    fdm2=${prf}${dn}.nc
  elif [ $n -eq $((dn-1)) ]; then
    fdp2=${prf}$(printf "%03d" $((10#$n-$n+1))).nc
  elif [ $n -eq $dn ]; then
    fdp1=${prf}$(printf "%03d" $((10#$n-$n+1))).nc
    fdp2=${prf}$(printf "%03d" $((10#$n-$n+2))).nc
  fi
  set +e 
  ndate=$( ncdump -v time -t $( ls $fdn0 | head -1 ) | tail -2 | head -1 | cut -d'"' -f2 | cut -d' ' -f1 )
  set -e 
  CDO mergetime $fdm2 $fdm1 $fdn0 $fdp1 $fdp2  $fda >/dev/null
  fp1=$dpc/${v}_${rcm}_${frq}_${n}_${rr}p.nc
  CDO setdate,"$ndate" -settime,"00" -timpctl,$rr $fda -timmin $fda -timmax $fda $fp1 >/dev/null 2>/dev/null 
#  rm $fda
done
#rm ${prf}???.nc
echo "## merging.."
CDO mergetime $dpc/${v}_${rcm}_${frq}_???_${rr}p.nc $fpc >/dev/null
#rm $dpc/${v}_${rcm}_${frq}_???_${rr}p.nc

for y in $( seq $y1 $y2 ); do
  echo "## ${rr}p at $y .."
  fty=$dpc/${v}_${rcm}_${frq}_${y}_${dn}.nc
  ftg=${fou}_${y}.nc
  CDO timsum -ge $fty $fpc $ftg >/dev/null
 # rm $fty
done
echo "## finalizing result."
CDO divc,$dy -timsum -mergetime ${fou}_????.nc $fou >/dev/null
#rm ${fou}_????.nc


echo "Done!"

}
