###############################################################################
# (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
## Script to dump Allen binary input (raw banks and MC info) for various data samples

# array containing output locations
declare -a out_arr=(
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/minbias/mag_down/"
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/Bs2PhiPhi/mag_down/"
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/Bs2PhiPhi/mag_up/"
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/Ds2KKPi/mag_down/"
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/Ds2KKPi/mag_up/"
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/JpsiMuMu/mag_down/"
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/KstEE/mag_down/"
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/KstEE/mag_up/"
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/KstMuMu/mag_down/"
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/KstMuMu/mag_up/"
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/Z2MuMu/mag_down/"
    "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/Z2MuMu/mag_up/"

    )

# Array containing input data
declare -a input_arr=(
    "GPU/BinaryDumpers/options/upgrade-minbias-magdown-scifi-v5-local.py"
    "GPU/BinaryDumpers/options/upgrade-BsPhiPhi-magdown-scifi-v5.py"
    "GPU/BinaryDumpers/options/upgrade-BsPhiPhi-magup-scifi-v5.py"
    "GPU/BinaryDumpers/options/upgrade-Ds2KKPi-magdown-scifi-v5.py"
    "GPU/BinaryDumpers/options/upgrade-Ds2KKPi-magup-scifi-v5.py"
    "GPU/BinaryDumpers/options/upgrade-JPsiMuMu-scifi_v5_local.py"
    "GPU/BinaryDumpers/options/upgrade-KstEE-magdown-scifi-v5.py"
    "GPU/BinaryDumpers/options/upgrade-KstEE-magup-scifi-v5.py"
    "GPU/BinaryDumpers/options/upgrade-KstMuMu-magdown-scifi-v5.py"
    "GPU/BinaryDumpers/options/upgrade-KstMuMu-magup-scifi-v5.py"
    "GPU/BinaryDumpers/options/upgrade-Z2MuMu-magdown-scifi-v5.py"
    "GPU/BinaryDumpers/options/upgrade-Z2MuMu-magup-scifi-v5.py"
    )

arraylength=${#out_arr[@]}

if [ ${arraylength} != ${#input_arr[@]} ]
then
    echo "input array and output array do not have the same length, aborting"
    exit 1
fi

for ((i = 0; i < ${arraylength}; i++));
do
    output_file=${out_arr[$i]}
    input=${input_arr[$i]}
    export OUTPUT_DIR="$output_file"
    echo "=============================================================================================="
    echo "Dumping binaries for input $input"
    echo "to output file $output_file"
    echo "=============================================================================================="
    ./run gaudirun.py GPU/BinaryDumpers/options/dump_banks_and_MC_info.py $input
done
