#!/bin/bash
#SBATCH -J bootstrapping
#SBATCH -o logs/bootstrapping.o
#SBATCH -e logs/bootstrapping.e
#SBATCH -t 24:00:00
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jciarlo@ictp.it
#SBATCH -p esp
{
set -eo pipefail
CDO(){
  cdo -O -L -f nc4 -z zip $@
}
startTime=$(date +"%s" -u)

export spc=$3 #xylocopa-violacea    
export obs=$2 #iNaturalist
export nam=$1 #EOBS-010-v25e
export nboot=$4 #1 #5000  # number of bootstap replications

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
dat=$5 #OBS
fcs=$6 #1995-2014

cdir=data/$dat/$nam/index
export idir=$cdir/$obs
export bdir=$idir/boot_${nboot}
sdir=$bdir/standard
mkdir -p $sdir

echo "##########################################"
echo "## spc   = $spc"
echo "## obs   = $obs"
echo "## meteo = $nam"
echo "## nboot = $nboot"
echo "##########################################"

export flog=$( basename $( eval ls $idir/${spc}_${obs}_${nam}.log ) )
script=tools/bootstrapping.ncl

todouble="warning:todouble: A bad value was passed to (string) todouble"
ncl -nQ $script | grep -v "$todouble"

# standardize actual data
echo "*** standardizing climate indices ***"
dflog=$sdir/$( basename $flog .log )_stats.csv
cols=$( head -1 $dflog )
vars=$( head -1 $dflog | cut -d' ' -f4- )
for v in $vars; do
  echo "--- $v ---"
  vc=0
  for vo in $cols; do
    vc=$(( $vc + 1 ))
    [[ $vo = $v ]] && break
  done
  avgv=$( head -2 $dflog | tail -1 | cut -d' ' -f$vc )
  stdv=$( tail -1 $dflog | cut -d' ' -f$vc )

  if [ $v = orog -o $v = popdenmean ]; then
    ivf=$( eval ls $cdir/*_${v}_${nam}.nc )
  else
    ivf=$( eval ls $cdir/*_${v}_${nam}_${fcs}.nc )
  fi
  ovf=$sdir/$( basename $ivf .nc )_${spc}.nc
# echo "CDO divc,$stdv -subc,$avgv $ivf $ovf"
  CDO divc,$stdv -subc,$avgv $ivf $ovf
done

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
