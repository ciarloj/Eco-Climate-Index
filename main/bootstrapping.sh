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

export spc=xylocopa-violacea    
export obs=iNaturalist
export nam=EOBS-010-v25e
export nboot=1 #5000  # number of bootstap replications

hdir=/home/netapp-clima-scratch/jciarlo/paleosim
if [ $nam = MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6 ]; then
  dat=RCMs
  fcs=1986-2005
elif [ $nam = EOBS-010-v25e ]; then
  dat=OBS
  fcs=1995-2014
fi
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

export flog=$( basename $( eval ls $idir/${spc}_${obs}_*_${nam}.log ) )
script=tools/bootstrapping.ncl

todouble="warning:todouble: A bad value was passed to (string) todouble"
ncl -nQ $script | grep -v "$todouble"

# standardize actual data
echo "*** standardizing climate indices ***"
dflog=$bdir/$( basename $flog .log ).csv
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

  [[ $v = orog ]] && ivf=$( eval ls $cdir/*_${v}_${nam}.nc ) || ivf=$( eval ls $cdir/*_${v}_${nam}_${fcs}.nc )
  ovf=$sdir/$( basename $ivf )
[[ $v = prsum ]] && set -x
  CDO divc,$stdv -subc,$avgv $ivf $ovf
done

endTime=$(date +"%s" -u)
elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
echo "##########################################"
echo "## Process complete!"
echo "## Elapsed time = $elapsed"
echo "##########################################"

}
