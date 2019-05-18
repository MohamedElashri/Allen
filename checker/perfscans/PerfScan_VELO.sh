cd ../..
cp cuda/velo/common/include/VeloDefinitions.cuh bkpfile.bkp

for par in 'max_scatter_seeding' 'max_scatter_forwarding' 
do
  for val in '0.05' '0.10' '0.20' '0.40' '0.60' '0.80' '0.90' '1.0'
  do
    echo 'Scanning VELO parameters' $par $val
    sed -i s/$par\ =\ \[^\;\]\*\;/$par\ =\ $val\f\;/g cuda/velo/common/include/VeloDefinitions.cuh
    cd build
    make -j 8 >& /tmp/WTF
    ./Allen -f /data/gligorov/BsPhiPhi -c 1 -t 1 -r 1 -m 3000 >& ../output/VELO-$par-$val-scan.stdout
    cp ../output/PrCheckerPlots.root ../output/PrChk-VELO-$par-$val-scan.root
    cp ../output/KalmanIPCheckerOutput.root ../output/KFChk-VELO-$par-$val-scan.root
    cp ../output/GPU_PVChecker.root ../output/PVChk-VELO-$par-$val-scan.root
    ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 1 -m 4000 >& ../output/VELO-$par-$val-tptscan.stdout    
    cd ..
    cp bkpfile.bkp cuda/velo/common/include/VeloDefinitions.cuh    
  done
done

for par in 'phi_extrapolation_base'
do
  for val in '0.02' '0.025' '0.030' '0.035' '0.040'
  do
    echo 'Scanning VELO parameters' $par $val
    sed -i s/$par\ =\ \[^\;\]\*\;/$par\ =\ $val\f\;/g cuda/velo/common/include/VeloDefinitions.cuh
    cd build
    make -j 8 >& /tmp/WTF
    ./Allen -f /data/gligorov/BsPhiPhi -c 1 -t 1 -r 1 -m 3000 >& ../output/VELO-$par-$val-scan.stdout
    cp ../output/PrCheckerPlots.root ../output/PrChk-VELO-$par-$val-scan.root
    cp ../output/KalmanIPCheckerOutput.root ../output/KFChk-VELO-$par-$val-scan.root
    cp ../output/GPU_PVChecker.root ../output/PVChk-VELO-$par-$val-scan.root
    ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 1 -m 4000 >& ../output/VELO-$par-$val-tptscan.stdout
    cd ..
    cp bkpfile.bkp cuda/velo/common/include/VeloDefinitions.cuh    
  done
done

for par in 'phi_extrapolation_coef'
do
  for val in '0.0001' '0.00015' '0.0002' '0.00025' '0.0003'
  do
    echo 'Scanning VELO parameters' $par $val
    sed -i s/$par\ =\ \[^\;\]\*\;/$par\ =\ $val\f\;/g cuda/velo/common/include/VeloDefinitions.cuh
    cd build
    make -j 8 >& /tmp/WTF
    ./Allen -f /data/gligorov/BsPhiPhi -c 1 -t 1 -r 1 -m 3000 >& ../output/VELO-$par-$val-scan.stdout
    cp ../output/PrCheckerPlots.root ../output/PrChk-VELO-$par-$val-scan.root
    cp ../output/KalmanIPCheckerOutput.root ../output/KFChk-VELO-$par-$val-scan.root
    cp ../output/GPU_PVChecker.root ../output/PVChk-VELO-$par-$val-scan.root
    ./Allen -f /data/gligorov/minbias -c 0 -n 10000 -t 3 -r 1 -m 4000 >& ../output/VELO-$par-$val-tptscan.stdout
    cd ..
    cp bkpfile.bkp cuda/velo/common/include/VeloDefinitions.cuh    
  done
done

cp bkpfile.bkp cuda/velo/common/include/VeloDefinitions.cuh
rm bkpfile.bkp
