cd ../..
cp cuda/UT/common/include/CompassUTDefinitions.cuh bkpfile.bkp

for par in 'max_considered_before_found' 
do
  for val in '1' '3' '6' '9' '12' '15'
  do
    echo 'Scanning CompassUT parameters' $par $val
    sed -i s/$par\ =\ \[^\;\]\*\;/$par\ =\ $val\;/g cuda/UT/common/include/CompassUTDefinitions.cuh 
    cd build
    make -j 8 >& /tmp/WTF
    ./Allen -f /data/gligorov/BsPhiPhi -c 1 -t 1 -r 1 -m 3000 >& ../output/CompassUT-$par-$val-scan.stdout
    cp ../output/PrCheckerPlots.root ../output/PrChk-CompassUT-$par-$val-scan.root
    cp ../output/KalmanIPCheckerOutput.root ../output/KFChk-CompassUT-$par-$val-scan.root
    ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 1 -m 4000 >& ../output/CompassUT-$par-$val-tptscan.stdout    
    cd ..
    cp bkpfile.bkp cuda/UT/common/include/CompassUTDefinitions.cuh
  done
done

cp bkpfile.bkp cuda/UT/common/include/CompassUTDefinitions.cuh
rm bkpfile.bkp

cp cuda/UT/common/include/UTDefinitions.cuh bkpfile.bkp

for par in 'minPT' 'minPTFinal'
do
  for val in '0.1' '0.2' '0.3' '0.4' '0.5' '0.6'
  do
    echo 'Scanning CompassUT parameters' $par $val
    sed -i s/$par\ =\ \[^f\]\*f/$par\ =\ $val\f/g cuda/UT/common/include/UTDefinitions.cuh 
    cd build
    make -j 8 >& /tmp/WTF
    ./Allen -f /data/gligorov/BsPhiPhi -c 1 -t 1 -r 1 -m 3000 >& ../output/CompassUT-$par-$val-scan.stdout
    cp ../output/PrCheckerPlots.root ../output/PrChk-CompassUT-$par-$val-scan.root
    cp ../output/KalmanIPCheckerOutput.root ../output/KFChk-CompassUT-$par-$val-scan.root
    ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 1 -m 4000 >& ../output/CompassUT-$par-$val-tptscan.stdout 
    cd ..
    cp bkpfile.bkp cuda/UT/common/include/UTDefinitions.cuh
  done
done

for par in 'minMomentum' 'minMomentumFinal'
do
  for val in '0.5' '1.5' '2.5' '3.5' '4.5' '6.0'
  do
    echo 'Scanning CompassUT parameters' $par $val
    sed -i s/$par\ =\ \[^f\]\*f/$par\ =\ $val\f/g cuda/UT/common/include/UTDefinitions.cuh 
    cd build
    make -j 8 >& /tmp/WTF
    ./Allen -f /data/gligorov/BsPhiPhi -c 1 -t 1 -r 1 -m 3000 >& ../output/CompassUT-$par-$val-scan.stdout
    cp ../output/PrCheckerPlots.root ../output/PrChk-CompassUT-$par-$val-scan.root
    cp ../output/KalmanIPCheckerOutput.root ../output/KFChk-CompassUT-$par-$val-scan.root
    ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 1 -m 4000 >& ../output/CompassUT-$par-$val-tptscan.stdout 
    cd ..
    cp bkpfile.bkp cuda/UT/common/include/UTDefinitions.cuh
  done
done

for par in 'yTol' 
do
  for val in '0.2' '0.35' '0.5' '0.65' '0.8' 
  do
    echo 'Scanning CompassUT parameters' $par $val
    sed -i s/$par\ =\ \[^f\]\*f/$par\ =\ $val\f/g cuda/UT/common/include/UTDefinitions.cuh 
    cd build
    make -j 8 >& /tmp/WTF
    ./Allen -f /data/gligorov/BsPhiPhi -c 1 -t 1 -r 1 -m 3000 >& ../output/CompassUT-$par-$val-scan.stdout
    cp ../output/PrCheckerPlots.root ../output/PrChk-CompassUT-$par-$val-scan.root
    cp ../output/KalmanIPCheckerOutput.root ../output/KFChk-CompassUT-$par-$val-scan.root
    ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 1 -m 4000 >& ../output/CompassUT-$par-$val-tptscan.stdout 
    cd ..
    cp bkpfile.bkp cuda/UT/common/include/UTDefinitions.cuh
  done
done

cp bkpfile.bkp cuda/UT/common/include/UTDefinitions.cuh
rm bkpfile.bkp
