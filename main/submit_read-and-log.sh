#!/bin/bash
{
set -eo pipefail


nam=EOBS-010-v25e
b=iNaturalist
csvs="apis-mellifera aedes-albopictus armadillidium-granulatum crematogaster-scutellaris vespa-orientalis"
csvs="xylocopa-violacea"


i=0
for c in $csvs; do
  [[ $i = 0 ]] && dep="" || dep="-d afterany:$jid"
  d=eur
  [[ $c = armadillidium-granulatum ]] && d=medi
  cin=$( ls data/OBS/${b}/${c}_${b}_*.csv )
  j=read_$c
  o=logs/${j}.o
  e=logs/${j}.e
  jid=$( sbatch -J $j -o $o -e $e $dep main/read-and-log.sh $cin $nam | cut -d' ' -f4 )
  echo "Submitted batch job $jid"
  i=$(( $i + 1 ))
done

}
