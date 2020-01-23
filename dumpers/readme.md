Produce input for HLT1 on GPUs
-------------------------------

These are instructions for how to produce input for [Allen](https://gitlab.cern.ch/lhcb-parallelization/Allen) (the HLT1 on GPUs project)
using the nightlies with lb-dev.

After logging in to lxplus7:

    LbLogin -c x86_64-centos7-gcc8-opt
    lb-dev --nightly lhcb-head Brunel/HEAD
    cd BrunelDev_HEAD/
    git lb-use Rec
    git lb-checkout Rec/master GPU
    make
    
`GPU` contains the dumpers for raw banks, geometries and hit objects, as well as
configuration and MC file scripts.
`Pr/PrMCTools` contains the PrTrackerDumper, from which MC information can be dumped
for every MCParticle. This is used for truth matching within HLT1 on GPUs. If you want to modify this code, you also need to check it out before calling make:

    git lb-checkout Rec/master Pr/PrMCTools


To dump the raw banks, geometry files and muon hit objects for SciFi raw bank version 5
minimum bias MC:

    ./run gaudirun.py GPU/BinaryDumpers/options/dump_banks.py GPU/BinaryDumpers/options/upgrade-minbias-magdown-scifi-v5-local.py

If you want Bs->PhiPhi MC instead, use `GPU/BinaryDumpers/options/upgrade-bsphiphi-magdown-scifi-v5-local.py` as input.
Similarly, for dumping the MC information, run:

    ./run gaudirun.py GPU/BinaryDumpers/options/dump_MC_info.py GPU/BinaryDumpers/options/upgrade-minbias-magdown-scifi-v5-local.py

The number of events to be dumped can be specified in `dump_MC_info.py` and `dump_banks.py` respectively.

For dumping both the raw banks and the MC info at the same time, use the combined script. The output directory where the dumped files are saved can be set with the environment variable `OUTPUT_DIR`, by default dumps are saved in the current directory.

    export $OUTPUT_DIR="/place/where/I/want/to/dump/to/"
    ./run gaudirun.py GPU/BinaryDumpers/options/dump_banks_and_MC_info.py GPU/BinaryDumpers/options/upgrade-minbias-magdown-scifi-v5-local.py

For processing many input data sets, a shell script can be used:

    source GPU/BinaryDumpers/options/process_input.sh

By default, the following output directories will be created in the current directory:

* `banks`: all raw banks (VP, UT, FTCluster, Muon)
* `muon_coords`, `muon_common_hits`: muon hit ojbects
* `geometry`: geometry description for the different sub-detectors needed within HLT1 on GPUs
* `MC_info/tracks`: binary files containing MC information needed to calculate track reconstruction efficiencies
* `MC_info/PVs`: binary files containing MC information needed to calculate PV reconstruction efficiencies
* `TrackerDumper`: ROOT files containing MC information for all dumped MCParticles as well as all hits in every sub-detector
* `forward_tracks`: FastForward tracks are dumped with their LHCbIDs, eta, p and pt; to be read into Allen and checked with the track checker there as a cross check

Saving of the ROOT files in the `TrackerDumper` directory is switched on by default in the configuration of the PrTrackerDumper, however it is explicitly set to false in the `dump_MC_info.py` and `dump_banks_and_MC_info.py` scripts to reduce the size of memory required by the dumped output.
If the ROOT files are required, their dumping can be enabled by setting `DumpToROOT=True` in these scripts.

For changing the output location, the OutputDirectory can be set in the configuration script, for example in dump_banks.py:
`dump_banks.OutputDirectory = "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/minbias/mag_down/banks"`
    
For the TrackerDumper, `OutputDirectory` is the directory for the ROOT files, `MCOutputDirectory` is the directory for the binary files.

Note: The "nightlies" might not be ready until after lunch time. Instead,
the build from a day before can be used. For example
`lb-dev --nightly lhcb-head Mon Brunel/HEAD --name BrunelDev_Mon`.
    
    
    
