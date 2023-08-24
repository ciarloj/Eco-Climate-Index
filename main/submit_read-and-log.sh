#!/bin/bash
{
set -eo pipefail


nam=$1 #EOBS-010-v25e
b=$2   #iNaturalist
#csvs="apis-mellifera aedes-albopictus armadillidium-granulatum crematogaster-scutellaris vespa-orientalis"
csvs=$3 #"xylocopa-violacea"

dat=$4
fcs=$5
vars=$6

i=0
for c in $csvs; do
  [[ $i = 0 ]] && dep="" || dep="-d afterany:$jid"
  d=* #eur
# [[ $c = armadillidium-granulatum ]] && d=medi
  cin=$( ls data/OBS/${b}/${c}_${b}.csv )
  j=read_${c}_${nam}
  o=logs/${j}.o
  e=logs/${j}.e
  jid=$( sbatch -J $j -o $o -e $e $dep main/read-and-log.sh $cin $nam $dat $fcs "$vars" | cut -d' ' -f4 )
  echo "Submitted batch job $jid"
  i=$(( $i + 1 ))
done

}
