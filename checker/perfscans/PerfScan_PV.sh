###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
outloc=../output/perfscans
cd ../..
cp cuda/PV/beamlinePV/include/BeamlinePVConstants.cuh bkpfile.bkp

for par in 'zmin' 
do
  for val in '-300' '-275' '-250' '-225' '-200'
  do
    echo 'Scanning PV parameters' $par $val
    sed -i s/$par\ =\ \[^\;\]\*\;/$par\ =\ $val\f\;/g cuda/PV/beamlinePV/include/BeamlinePVConstants.cuh
    cd build
    make -j 8 >& /tmp/WTF
    ./Allen -f /data/gligorov/signals/Bs2PhiPhi/mag_down -c 1 -m 9000 >& $outloc\/PV-$par-$val-scan.stdout
    cp ../output/GPU_PVChecker.root $outloc\/PVChk-PV-$par-$val-scan.root
    ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 10 -m 4000 >& $outloc\/PV-$par-$val-tptscan.stdout    
    cd ..
    cp bkpfile.bkp cuda/PV/beamlinePV/include/BeamlinePVConstants.cuh
  done
done

for par in 'zmax' 
do
  for val in '200' '225' '250' '275' '300'
  do
    echo 'Scanning PV parameters' $par $val
    sed -i s/$par\ =\ \[^\;\]\*\;/$par\ =\ $val\f\;/g cuda/PV/beamlinePV/include/BeamlinePVConstants.cuh
    cd build
    make -j 8 >& /tmp/WTF
    ./Allen -f /data/gligorov/signals/Bs2PhiPhi/mag_down -c 1 -m 9000 >& $outloc\/PV-$par-$val-scan.stdout
    cp ../output/GPU_PVChecker.root $outloc\/PVChk-PV-$par-$val-scan.root
    ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 10 -m 4000 >& $outloc\/PV-$par-$val-tptscan.stdout    
    cd ..
    cp bkpfile.bkp cuda/PV/beamlinePV/include/BeamlinePVConstants.cuh
  done
done

for par in 'maxChi2' 
do
  for val in '7' '8' '9' '10' '11'
  do
    echo 'Scanning PV parameters' $par $val
    sed -i s/$par\ =\ \[^\;\]\*\;/$par\ =\ $val\f\;/g cuda/PV/beamlinePV/include/BeamlinePVConstants.cuh
    cd build
    make -j 8 >& /tmp/WTF
    ./Allen -f /data/gligorov/signals/Bs2PhiPhi/mag_down -c 1 -m 9000 >& $outloc\/PV-$par-$val-scan.stdout
    cp ../output/GPU_PVChecker.root $outloc\/PVChk-PV-$par-$val-scan.root
    ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 10 -m 4000 >& $outloc\/PV-$par-$val-tptscan.stdout    
    cd ..
    cp bkpfile.bkp cuda/PV/beamlinePV/include/BeamlinePVConstants.cuh
  done
done

for par in 'minTracksInSeed' 
do
  for val in '1.5' '2.0' '2.5' '3.0' '3.5'
  do
    echo 'Scanning PV parameters' $par $val
    sed -i s/$par\ =\ \[^\;\]\*\;/$par\ =\ $val\f\;/g cuda/PV/beamlinePV/include/BeamlinePVConstants.cuh
    cd build
    make -j 8 >& /tmp/WTF
    ./Allen -f /data/gligorov/signals/Bs2PhiPhi/mag_down -c 1 -m 9000 >& $outloc\/PV-$par-$val-scan.stdout
    cp ../output/GPU_PVChecker.root $outloc\/PVChk-PV-$par-$val-scan.root
    ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 10 -m 4000 >& $outloc\/PV-$par-$val-tptscan.stdout    
    cd ..
    cp bkpfile.bkp cuda/PV/beamlinePV/include/BeamlinePVConstants.cuh
  done
done

cp bkpfile.bkp cuda/PV/beamlinePV/include/BeamlinePVConstants.cuh
rm bkpfile.bkp

cd checker/perfscans
