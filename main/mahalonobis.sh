#!/bin/bash
#SBATCH -J mahalonobis
#SBATCH -o logs/mah.o
#SBATCH -e logs/mah.e
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

export spc=$3 #xylocopa-violacea   
export obs=$2 #iNaturalist
export nam=$1 #EOBS-010-v25e
nboot=$4 #1 #5000  # number of bootstap replications

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
dat=$5 #OBS
fcs=$6 #1995-2014

ndir=data/$dat/$nam/index/$obs/boot_${nboot}/standard/pca
mdir=$ndir/mahalonobis
mkdir -p $mdir
script=$hdir/tools/stats.ncl

echo "##########################################"
echo "## spc   = $spc"
echo "## obs   = $obs"
echo "## model = $nam"
echo "##########################################"

#check number of components required
lpca=logs/pca_${spc}_${nam}.out
lcomp=$( cat $lpca | grep 'Cumulative Proportion' | wc -l )
tcomp=0.85 #threshold for cumulative proportion
ncomp=0
for l in $( seq 1 $lcomp ); do
  line=$( cat $lpca | grep 'Cumulative Proportion' | head -$l | tail -1 )
  for c in $( seq 1 5 ); do
    cc=$(( 2 + $c ))
    cp=$( eval echo $line | cut -d' ' -f$cc )
    ncomp=$(( $ncomp + 1 ))
    echo "comp # $ncomp with cum.prop = $cp"
    [[ $cp > $tcomp ]] && break
  done
  [[ $cp > $tcomp ]] && break
done
export ncomp=$ncomp

#count the number of components
#export ncomp=$( ls $ndir/${spc}_${obs}_${nam}_comp*csv | wc -l )
echo ncomp = $ncomp

export scrf=$( ls $ndir/${spc}_${obs}_${nam}_scores.csv )
combi=""
for c in $( seq 1 $ncomp ); do
  echo $c ..
  export cn=$c
  stt=$( ncl -nQ $script )
  avg=$( echo $stt | cut -d, -f2 )
  std=$( echo $stt | cut -d, -f1 )
  lim=$( echo $stt | cut -d, -f3 )

  echo "## $cn avg=$avg std=$std lim=$lim ##"
  ncf=$ndir/comp${cn}_${nam}_${obs}_${spc}_${fcs}.nc
  ouf=$mdir/$( basename $ncf )
  set0='setmissval,-9999 -setrtoc,-inf,0,0'
  #echo "CDO $set0 -addc,1 -mulc,-1 -divc,$lim -abs -divc,$std -subc,$avg $ncf $ouf"
  CDO $set0 -addc,1 -mulc,-1 -divc,$lim -abs -divc,$std -subc,$avg $ncf $ouf

  if [ $c -lt $ncomp ]; then
    [[ $c = 1 ]] && combi="$combi mul $ouf" || combi="${combi} -mul $ouf"
  else
    combi="${combi} $ouf"
  fi
done

echo "## combining ..."
ecf=$mdir/EcoIndex_${nam}_${obs}_${spc}_${fcs}.nc
#echo "CDO $combi $ecf"
CDO $combi $ecf

#finding historical max
tmp=$mdir/EcoIndex_${nam}_${obs}_${spc}_${fcs}_tmp.nc
CDO fldmax $ecf $tmp
set +e 
emx=$( ncdump -v comp $tmp | tail -2 | head -1 | cut -d' ' -f3 ) 
set -e
#echo "CDO divc,$emx $ecf $tmp"
CDO divc,$emx $ecf $tmp 
mv $tmp $ecf

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
