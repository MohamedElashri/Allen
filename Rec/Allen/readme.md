Call Allen from Gaudi, event loop directed by Brunel or Moore
=============================

This readme explains how to setup Allen as Gaudi project, calling Allen either from Brunel or Moore. This means that Allen is called one event at a time and the event loop is governed by Brunel or Moore.
The described setup works on lxplus.

```
lb-set-platform x86_64-centos7-gcc9-opt
export PATH=/cvmfs/sft.cern.ch/lcg/contrib/CMake/3.14.2/Linux-x86_64/bin:$PATH
export CMAKE_PREFIX_PATH=/cvmfs/lhcbdev.cern.ch/nightlies/lhcb-head/Tue/:$CMAKE_PREFIX_PATH
```

If a specific version of [Rec](https://gitlab.cern.ch/lhcb/Rec) is needed, Rec needs to be compiled as well. If not, you can skip these instructions and use Rec from the nightlies instead.

Create a new directory `Allen_Gaudi_integration` and clone both `Allen` and `Rec` into this new directory. 
```
ls Allen_Gaudi_integration
Allen Rec

```

```
cd Rec
lb-project-init
make configure
make install
cd ..
export CMAKE_PREFIX_PATH=/path/to/user/directory/Allen_Gaudi_integration:$CMAKE_PREFIX_PATH
cd Allen
lb-project-init
make configure
make install
```

Note that this setup uses the nightlies from Tuesday. Adopt the day of the nightly build according to when you are building. Possibly check that the nightly build was successful.


Call Allen from Brunel
---------------------------
Brunel is the configuration package used to call the LHCb baseline reconstruction sequence. Since recently, Moore is being used for preferentially.
Clone `Brunel` into the directory `Allen_Gaudi_integration` as well.

In Brunel, change `CMakeLists.txt` line 20 to `USE Allen	v0r7` and delete the `Rec/BrunelCache` directory, then:
```
cd Brunel
lb-project-init
make configure
make install
```

The calls to `lb-project-init` are only required when setting up the directories for the first time.

Call the executable from within the Brunel directory:
```
./build.x86_64-centos7-gcc9-opt/run gaudirun.py ../Allen/Online/AllenIntegration/options/run_allen_in_brunel.py ../Rec/GPU/BinaryDumpers/options/upgrade-minbias-magdown-scifi-v5.py
```

Call Allen from Moore
-------------------------
Clone `Moore` into the directory `Allen_Gaudi_integration` as well.
If https://gitlab.cern.ch/lhcb/Moore/merge_requests/378 is not yet merged, checkout that branch in Moore.
```
cd Moore
lb-project-init
make configure
make install
```

Call the executable from within the Moore directory as in the following examples:
```
./build.x86_64-centos7-gcc9-opt/run gaudirun.py Hlt/Moore/tests/options/default_input_and_conds_hlt1.py Hlt/RecoConf/options/hlt1_reco_allen_track_reconstruction.py
```
This will call the full Allen sequence, convert reconstructed tracks to Rec objects and run the MC checkers for track reconstruction efficiencies. The input sample is defined in `Hlt/Moore/tests/options/default_input_and_conds_hlt1.py`.
For a comparison of the Allen standalone track checker and the PrChecker called from Moore, it can be helpful to dump the binary files required for Allen standalone running at the same time
as calling the track reconstruction checker in Moore. For this, the dumping can be enabled in the script by setting `dumpBinaries = True`.

If you want to run the PV checker, you need to use [this](https://gitlab.cern.ch/lhcb/Rec/tree/dovombru_twojton_pvchecker) branch in Rec and the following executable:
```
./build.x86_64-centos7-gcc9-opt/run gaudirun.py Hlt/Moore/tests/options/default_input_and_conds_hlt1.py Hlt/RecoConf/options/hlt1_reco_allen_pvchecker.py
```

To check the IP resolution:
```
./build.x86_64-centos7-gcc9-opt/run gaudirun.py Hlt/Moore/tests/options/default_input_and_conds_hlt1.py Hlt/RecoConf/options/hlt1_reco_allen_IPresolution.py
```
To check the track momentum resolution:
```
./build.x86_64-centos7-gcc9-opt/run gaudirun.py Hlt/Moore/tests/options/default_input_and_conds_hlt1.py Hlt/RecoConf/options/hlt1_reco_allen_trackresolution.py
```

To check the muon identification efficiency and misID efficiency:
```
./build.x86_64-centos7-gcc9-opt/run gaudirun.py Hlt/Moore/tests/options/default_input_and_conds_hlt1.py Hlt/RecoConf/options/hlt1_reco_allen_muonid_efficiency.py
```

The scripts in `Moore/Hlt/RecoConf/scripts/` can be used to produce plots of the various efficiencies and resolutions from the ROOT files produced by one of the previous calls to Moore.

Call HLT1 selection efficiency script
------------------------------
The [mooreanalysis](https://gitlab.cern.ch/lhcb/mooreanalysis) repository contains the HLT efficiency checking script.
If this [branch](https://gitlab.cern.ch/lhcb/mooreanalysis/tree/dovombru_rjhunter-HltEfficiencyChecker_for_Allen) is not yet merged in the mooreanalysis repository, switch to this branch.
Check whether the merge requests for LHCb and Analysis linked in [this MR](https://gitlab.cern.ch/lhcb/mooreanalysis/merge_requests/1) are merged. If not, you need to clone the LHCb and Analysis repositories
in the same directory where all the other projects are already located. Then compile LHCb -> Analysis -> Rec -> Allen -> Moore -> mooreanalysis.
If the MRs are already merged, you can use the nightlies.

To run the efficiency checking script, call it from the top-level directory, so from `Allen_Gaudi_integration`:

```
./mooreanalysis/build.x86_64-centos7-gcc9-opt/run mooreanalysis/HltEfficiencyChecker/scripts/HltEfficiencyChecker.py --data MiniBrunel_2018_MinBias_FTv4_DIGI --events 100 --lines Hlt1SingleMuonLine
```

For this to work, verify that the input for Allen configurations is set to `DetectorConfigurationPath="Allen/input/detector_configuration/down/"` and `AlgorithmConfigurationPath="Allen/configuration/constants/"` [here](https://gitlab.cern.ch/lhcb/Moore/blob/dovombru_Allen_Moore_integration/Hlt/RecoConf/python/RecoConf/hlt1_allen.py#L38).
If this was not the case, change it accordingly and `make install` Moore before calling the mooreanalysis script.

This will run on minimum bias data. mooreanalysis/HltEfficiencyChecker/scripts/HltEfficiencyChecker.py contains a dictionary with all the files that can be used. If SciFi raw bank version 6 is used, make sure the Allen sequence is configured to decode that version. The default in Allen is SciFi raw bank version 4.
`Hlt1SingleMuonLine` indicates which line should be analyzed. The efficiency script still needs to be adopted for the Allen lines.


