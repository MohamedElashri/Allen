outloc=../output/perfscans
cd ../..
cp cuda/global_event_cut/include/GlobalEventCutConfiguration.cuh bkpfile.bkp

par_low=min_scifi_ut_clusters
par_hi=max_scifi_ut_clusters

declare -a vals_low
declare -a vals_hi

vals_low=( 0 2000 3000 4000 5000 6000 7000 8000 9000 10000 )
vals_hi=( 2000 3000 4000 5000 6000 7000 8000 9000 10000 25000 )

for entry in 0 1 2 3 4 5 6 7 8 9
do
  echo 'Scanning GEC parameters' $val_low $val_hi
  sed -i s/$par_low\ =\ \[^\;\]\*\;/$par_low\ =\ ${vals_low[$entry]}\;/g cuda/global_event_cut/include/GlobalEventCutConfiguration.cuh
  sed -i s/$par_hi\ =\ \[^\;\]\*\;/$par_hi\ =\ ${vals_hi[$entry]}\;/g cuda/global_event_cut/include/GlobalEventCutConfiguration.cuh
  cd build
  make -j 8 >& /tmp/WTF
  ./Allen -f /data/gligorov/signals/Bs2PhiPhi/mag_down -c 1 -m 3000 >& $outloc\/GEC-$val_low-$val_hi-scan.stdout
  ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 1 -m 4000 >& $outloc\/GEC-$val_low-$val_hi-tptscan.stdout    
  cd ..
  cp bkpfile.bkp cuda/global_event_cut/include/GlobalEventCutConfiguration.cuh
done

cp bkpfile.bkp cuda/global_event_cut/include/GlobalEventCutConfiguration.cuh
rm bkpfile.bkp
cd checker/perfscans
