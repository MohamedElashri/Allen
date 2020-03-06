Produce binary input for Allen
================================

These are instructions for how to produce binary input for Allen from lxplus using Brunel or Moore.

Brunel
-------

Follow instructions [here](https://gitlab.cern.ch/lhcb/Allen/tree/allen_tdr/Rec/Allen#call-allen-from-brunel) to call Allen from Brunel.  

Note that after the installation, all of the following commands are executed from within the Brunel directory.
  
This directory (`dumpers`) contains the dumpers for raw banks, geometries and hit objects, as well as
configuration and MC file scripts. In the [Rec](https://gitlab.cern.ch/lhcb/Rec) project, `Pr/PrMCTools` contains the PrTrackerDumper, from which MC information can be dumped
for every MCParticle. This is used for truth matching within Allen.

To dump the raw banks, geometry files and muon hit objects for SciFi raw bank version 5
minimum bias MC, go to your Brunel directory, then (assuming Brunel lives in the same directory as Allen):

    ./build.x86_64-centos7-gcc9-opt/run gaudirun.py ../Allen/dumpers//BinaryDumpers/options/dump_banks.py ../Allen/dumpers/BinaryDumpers/options/upgrade-minbias-magdown-scifi-v5-local.py

If you want Bs->PhiPhi MC instead, use `../Allen/dumpers/BinaryDumpers/options/upgrade-bsphiphi-magdown-scifi-v5-local.py` as input.
Similarly, for dumping the MC information, run:

    ./build.x86_64-centos7-gcc9-opt/run gaudirun.py ../Allen/dumpers/BinaryDumpers/options/dump_MC_info.py ../Allen/dumpers/BinaryDumpers/options/upgrade-minbias-magdown-scifi-v5-local.py

The number of events to be dumped can be specified in `dump_MC_info.py` and `dump_banks.py` respectively.

For dumping both the raw banks and the MC info at the same time, use the combined script. The output directory where the dumped files are saved can be set with the environment variable `OUTPUT_DIR`, by default dumps are saved in the current directory.

    export $OUTPUT_DIR="/place/where/I/want/to/dump/to/"
    ./build.x86_64-centos7-gcc9-opt/run gaudirun.py ../Allen/dumpers/BinaryDumpers/options/dump_banks_and_MC_info.py ../Allen/dumpers/BinaryDumpers/options/upgrade-minbias-magdown-scifi-v5-local.py

For processing many input data sets, a shell script can be used:

    source ../Allen/dumpers/BinaryDumpers/options/process_input.sh

By default, the following output directories will be created in the current directory:

* `banks`: all raw banks (VP, UT, FTCluster, Muon)
* `muon_coords`, `muon_common_hits`: muon hit ojbects
* `geometry`: geometry description for the different sub-detectors needed within HLT1 on GPUs
* `MC_info/tracks`: binary files containing MC information needed to calculate track reconstruction efficiencies
* `MC_info/PVs`: binary files containing MC information needed to calculate PV reconstruction efficiencies
* `TrackerDumper`: ROOT files containing MC information for all dumped MCParticles as well as all hits in every sub-detector
* `forward_tracks`: FastForward tracks are dumped with their LHCbIDs, eta, p and pt; to be read into Allen and checked with the track checker there as a cross check* 

In addition to the banks dumped here, ODIN banks are required to run Allen in standalone mode. Please follow the instructions [here](https://gitlab.cern.ch/lhcb/Allen/blob/allen_tdr/readme.md#where-to-find-input) on how to create those.

Saving of the ROOT files in the `TrackerDumper` directory is switched on by default in the configuration of the PrTrackerDumper, however it is explicitly set to false in the `dump_MC_info.py` and `dump_banks_and_MC_info.py` scripts to reduce the size of memory required by the dumped output.
If the ROOT files are required, their dumping can be enabled by setting `DumpToROOT=True` in these scripts.

For changing the output location, the OutputDirectory can be set in the configuration script, for example in dump_banks.py:
`dump_banks.OutputDirectory = "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/minbias/mag_down/banks"`
    
For the TrackerDumper, `OutputDirectory` is the directory for the ROOT files, `MCOutputDirectory` is the directory for the binary files.

Moore
--------

The binary bank output can also be dumped with Moore. In this case follow [these](https://gitlab.cern.ch/lhcb/Allen/blob/dovombru_Gaudi_Allen_integration/Online/AllenIntegration/readme.md#call-allen-from-moore) instruction to call Allen from Moore.
The dumping of banks to file needs to be enabled [here](https://gitlab.cern.ch/lhcb/Moore/blob/dovombru_Allen_Moore_integration/Hlt/RecoConf/python/RecoConf/hlt1_allen.py#L28).

    
    
    
