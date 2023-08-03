#!/bin/bash
#SBATCH -N 1
#SBATCH -p esp
#SBATCH -t 24:00:00
#SBATCH -o logs/heatmap.o
#SBATCH -e logs/heatmap.e
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jciarlo@ictp.it
{
set -eo pipefail
#startTime=$(date +"%s" -u)

hdir=/home/netapp-clima-scratch/jciarlo/paleosim/

export spc=apis-mellifera-ligustica
export obs=iNaturalist
export nam=EOBS-010-v25e

[[ $nam = MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6 ]] && dat=RCMs
[[ $nam = EOBS-010-v25e ]] && dat=OBS
export mg=r99 # variable to use model grid

inddir=$hdir/data/$dat/$nam/index
obsdir=$inddir/$obs

export idir=$obsdir/images/
export tdir=$obsdir/heatmaps/
mkdir -p $idir $tdir

export flog=$( eval ls $obsdir/${spc}_${obs}_*_${nam}.log )
export fgrd=$( eval ls $inddir/*_${mg}_${nam}_*.nc )

mdims=$( ncdump -h $fgrd | grep $mg | grep '(' | head -1 | cut -d'(' -f2 | cut -d')' -f1 )
d1=$( echo $mdims | cut -d' ' -f1 | cut -d, -f1 )
d2=$( echo $mdims | cut -d' ' -f2 | cut -d, -f1 )
d3=$( echo $mdims | cut -d' ' -f3 )
if [ $d1 != time ]; then
  echo Dim1 = $d1
  echo back to the script...
  exit 1
fi
chk2lat=$( echo $d2 | grep -i LAT )
if [ ! -z $chk2lat ]; then
  export lat=$d2
  chk3lon=$( echo $d3 | grep -i LON )
  if [ ! -z $chk3lon ]; then
    export lon=$d3
  else
    echo "You have found a lat(d2): $lat"
    echo "  ...but no lon!"
    echo "dims = $mdims"
    exit 1
  fi
else
  chk2lon=$( echo $d2 | grep -i LON )
  if [ ! -z $chk2lon ]; then
    export lon=$d2
    echo "lons listed before lat - will give problems in script!"
    chk3lat=$( echo $d3 | grep -i LAT )
    if [ ! -z $chk3lat ]; then
      export lat=$d3
    else
      echo "You have found a lon(d2): $lon"
      echo "  ...but no lat!"
      echo "dims = $mdims"
      exit 1
    fi
  else
    echo "lat and lon not identified"
    echo "dims = $mdims"
    exit 1
  fi
fi

  ncl -Q $hdir/tools/plot_obs_heatmap.ncl | grep -v 'replacing with missing value'

#fdir=$hdir/data/RCMs/$rcm/index
#of=$fdir/${spc}_${dbs}_${rcm}.nc
#ncks -O -x -v r99 $of $of

#endTime=$(date +"%s" -u)
#elapsed=$(date -u -d "0 $endTime seconds - $startTime seconds" +"%H:%M:%S")
#echo "##########################################"
#echo "## Process complete!"
#echo "## Elapsed time = $elapsed"
#echo "##########################################"

}

