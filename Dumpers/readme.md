Produce binary input for Allen with Moore
================================

These are instructions for how to produce binary input for Allen from lxplus Moore.


Follow [these](../Rec/Allen/readme.md) instruction to call Allen from Moore and use the options script [dump_binary_input_for_standalone_Allen.py](https://gitlab.cern.ch/lhcb/Moore/blob/master/Hlt/RecoConf/options/dump_binary_input_for_standalone_Allen.py).
The output directory where the dumped binaries are stored can be specified with `outputDir = "dump/"`.

This directory (`Dumpers`) contains the dumpers for raw banks, geometries and hit objects, as well as
configuration and MC file scripts. In the [Rec](https://gitlab.cern.ch/lhcb/Rec) project, `Pr/PrMCTools` contains the PrTrackerDumper, from which MC information can be dumped
for every MCParticle. This is used for truth matching within Allen.


By default, the following output directories will be created in the current directory:

* `banks`: all raw banks (VP, UT, FTCluster, Muon)
* `geometry`: geometry description for the different sub-detectors needed within HLT1 on GPUs
* `MC_info/tracks`: binary files containing MC information needed to calculate track reconstruction efficiencies
* `MC_info/PVs`: binary files containing MC information needed to calculate PV reconstruction efficiencies
* `TrackerDumper`: ROOT files containing MC information for all dumped MCParticles as well as all hits in every sub-detector

In addition to the banks dumped here, ODIN banks are required to run Allen in standalone mode. Please follow the instructions [here](https://gitlab.cern.ch/lhcb/Allen/blob/master/readme.md#where-to-find-input) on how to create those.

Saving of the ROOT files in the `TrackerDumper` directory is switched on by default in the configuration of the PrTrackerDumper, however it is explicitly set to false in the `dump_MC_info.py` and `dump_banks_and_MC_info.py` scripts to reduce the size of memory required by the dumped output.
If the ROOT files are required, their dumping can be enabled by setting `DumpToROOT=True` in these scripts.

For changing the output location, the OutputDirectory can be set in the configuration script, for example in dump_banks.py:
`dump_banks.OutputDirectory = "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/minbias/mag_down/banks"`
    
For the TrackerDumper, `OutputDirectory` is the directory for the ROOT files, `MCOutputDirectory` is the directory for the binary files.



    
    
    
