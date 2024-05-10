#!/bin/bash
#SBATCH -J tas_cwfi
#SBATCH -o logs/tas_cwfi.o
#SBATCH -e logs/tas_cwfi.e
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

# heat wave frequency index - 6 consec day with warm days above 90th percentile 
# 90th percentile of 5-yearly day period
v=tas
idx=cwfi 
fin=$din/${v}_${nam}_${frq}_${yrs}.nc
fou=$dou/${v}_${idx}_${nam}_${fcs}.nc
rr=10

echo "##########################################"
echo "## index = $idx($v)"
echo "## data  = $nam"
echo "##########################################"
dsy=$din/.sy_${idx}_$fcs
dpp=$din/p$rr
mkdir -p $dsy $dpp
vo=cold_spell_days_index_wrt_10th_percentile_of_reference_period

[[ -z $SLURM_JOB_ID ]] && rtyp="bash" || rtyp="slurm"

frr=$dpp/${v}_${nam}_${frq}_${fcs}_p${rr}.nc
#if [ ! -f $frr ]; then
for y in $( seq $y1 $y2 ); do
  echo "## preparing $y .."
  fyr=$dsy/${v}_${nam}_${frq}_${y}.nc
  CDO selyear,$y $fin $fyr >/dev/null
  set +e
  d=$( ncdump -h $fyr | grep -i time | head -1 | cut -d'(' -f2 | cut -d' ' -f1 )
  set -e
  if [ $d != 360 -a $d != 365 -a $d != 366 ]; then
    if [ $d = 364 ]; then
      # some simulations started from day 02 or 03
      # check if first timestep is day 02 or 03
      ts1=$dsy/${v}_${nam}_${frq}_${y}_ts1.nc
      CDO seltimestep,1 $fyr $ts1
      dck=$( ncdump -v time -t $ts1 | tail -2 | head -1 | cut -d'"' -f2 | cut -d- -f3 | cut -d' ' -f1 )
      if [ $dck = 02 ]; then
      # replicating day 1 for these cases
        ts1s=$dsy/${v}_${nam}_${frq}_${y}_ts1s.nc
        CDO setday,01 $ts1 $ts1s
        rm $ts1
        CDO mergetime $ts1s $fyr ${fyr}_mod.nc
        mv ${fyr}_mod.nc $fyr
        d=365 
        rm $ts1s
      elif [ $dck = 03 ]; then
      # replicating day 1 and 2 for these cases
        ts1s=$dsy/${v}_${nam}_${frq}_${y}_ts1s.nc
        ts2s=$dsy/${v}_${nam}_${frq}_${y}_ts2s.nc
        CDO setday,01 $ts1 $ts1s
        CDO setday,02 $ts1 $ts2s
        rm $ts1
        CDO mergetime $ts1s $ts2s $fyr ${fyr}_mod.nc
        mv ${fyr}_mod.nc $fyr
        d=365
        rm $ts1s $ts2s
     else
        rm $ts1
        echo "Calendar Error! y=$y d="$d
        exit 1
      fi
    else
      echo "Calendar Error! y=$y d="$d
      exit 1
    fi
  fi
  if [ $d -gt 365 ]; then
    echo "trimming $y.."
    flp=$dsy/leap.nc
    CDO delete,day=29,month=2 $fyr $flp >/dev/null
    mv $flp $fyr
    set +e
    d=$( ncdump -h $fyr | grep -i time | head -1 | cut -d'(' -f2 | cut -d' ' -f1 )
    set -e
  fi
  fny=$dsy/${v}_${nam}_${frq}_${y}_${d}.nc
  mv $fyr $fny
  for t in $( seq -w 1 $d ); do
    [[ $rtyp = bash ]] && echo -n -e "\r## extracting $t/$d .."
    fts=$dsy/${v}_${nam}_${frq}_${y}_${d}_${t}.nc
    CDO seltimestep,$t $fny $fts >/dev/null
    if [ $rtyp = bash ]; then
      [[ $t = $d ]] && echo -n -e "\r\e[0K"
    fi
  done
done
dn=$d
for n in $( seq -w 1 $dn ); do
  echo "## working on ts $n .."
  prf=$dsy/${v}_${nam}_${frq}_????_${dn}_
  fda=$dsy/${v}_${nam}_${frq}_${n}_data.nc
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
  fp1=$dpp/${v}_${nam}_${frq}_${n}_${rr}p.nc
  CDO setdate,"$ndate" -settime,"00" -timpctl,$rr $fda -timmin $fda -timmax $fda $fp1 >/dev/null 2>/dev/null 
  rm $fda
done
rm ${prf}???.nc
echo "## merging.."
CDO mergetime $dpp/${v}_${nam}_${frq}_???_${rr}p.nc $frr >/dev/null
rm $dpp/${v}_${nam}_${frq}_???_${rr}p.nc
#fi

for y in $( seq $y1 $y2 ); do
  echo "## ${rr}p at $y .."
  fty=$dsy/${v}_${nam}_${frq}_${y}_${dn}.nc
  ftg=$dsy/$( basename $fou .nc)_${y}-cwfi.nc
  CDO eca_cwfi,6 $fty $frr $ftg >/dev/null
  rm $fty
done
echo "## finalizing result."
files=$dsy/$( basename $fou .nc)_????-cwfi.nc
CDO chname,$vo,$idx -selvar,$vo -divc,$dy -timsum -mergetime $files $fou >/dev/null
ncatted -O -a long_name,$idx,m,c,"yearly_mean_cold_wave_frequency_index" $fou
ncatted -O -a standard_name,$idx,m,c,"Yearly Mean 6+ Consecutive days below 5-day 10p temperature" $fou
ncatted -O -a units,$idx,m,c,"days/year" $fou
rm $dsy/$( basename $fou .nc)_????-cwfi.nc

rmdir $dsy

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
