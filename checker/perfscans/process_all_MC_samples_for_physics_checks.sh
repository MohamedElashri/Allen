###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
allen_dir="/home/vgligoro/Allen_master_update_checkers"
build_dir=${allen_dir}"/build"

declare -a sample_arr=(
    "Bs2PhiPhi"
    "Ds2KKPi"
    "JpsiMuMu"
    "KstEE"
    "KstMuMu"
    "Z2MuMu"
    "minbias"
    "Ks02MuMu"
)

arraylength=${#sample_arr[@]}

cd $build_dir

for sample in "${sample_arr[@]}"
do
    input="/scratch/dvombruc/"${sample}"/mag_down"
    output_dir=$allen_dir"/output/"${sample}"/"
    echo "=========================================================="
    echo " Running Allen on $sample , saving output to $output_dir"
    echo "=========================================================="
    if [ ! -d "$output_dir" ]; then
        mkdir $output_dir
        echo "Creating directory $output_dir"
    fi
    ./Allen -f $input -m 9000 -n 30000 >& ${output_dir}${sample}.stdout
    cp ../output/PrCheckerPlots.root $output_dir\PrCheckerPlots-$sample.root
    cp ../output/GPU_PVChecker.root $output_dir\GPU_PVChecker-$sample.root
    cp ../output/KalmanIPCheckerOutput.root $output_dir\KalmanIPCheckerOutput-$sample.root
    cp ../output/SelCheckerTuple.root $output_dir\SelCheckerTuple-$sample.root

done
