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

tim=$7
tsup=""
[[ ! -z $tim ]] && tsup=_$tim

cdir=data/$dat/$nam/index
export idir=$cdir/$obs
export bdir=$idir/boot_${nboot}
#sdir=$bdir/standard
mkdir -p $bdir

echo "##########################################"
echo "## spc   = $spc"
echo "## obs   = $obs"
echo "## meteo = $nam"
echo "## nboot = $nboot"
echo "##########################################"

#if [ ! -z $tim -a $tim != "hist" ]; then
# hbase=href
# hflog=$( eval ls $bdir/${spc}_${obs}_${nam}_hist_stats.csv )
# dflog=$hflog
#else
# export hbase=basic
  export flog=$( basename $( eval ls $idir/${spc}_${obs}_${nam}${tsup}.log ) )
  dflog=$bdir/$( basename $flog .log )_stats.csv

  script=tools/bootstrapping.ncl
  todouble="warning:todouble: A bad value was passed to (string) todouble"
  ncl -nQ $script | grep -v "$todouble"
#fi

# standardize actual data
istand=false
if [ $istand = true ]; then
  echo "*** standardizing climate indices ***"
  sdir=$bdir/standard
  mkdir -p $sdir
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

    if [ -z $tim -a  $v = orog -o $v = popdenmean ]; then
      ivf=$( eval ls $cdir/*_${v}_${nam}.nc )
    else
      ivf=$( eval ls $cdir/*_${v}_${nam}_${fcs}.nc )
    fi
    ovf=$sdir/$( basename $ivf .nc )_${spc}.nc
  # echo "CDO divc,$stdv -subc,$avgv $ivf $ovf"
    CDO divc,$stdv -subc,$avgv $ivf $ovf
  done
fi

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
