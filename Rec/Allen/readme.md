Call Allen from Gaudi, event loop directed by Moore
=============================
The software can be compiled either based on the nightlies or by compiling the full stack, as described [here](https://gitlab.cern.ch/lhcb/Allen/-/blob/master/readme.md#call-allen-with-gaudi-steer-event-loop-from-moore).


Call Allen from Moore
-------------------------

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
The [MooreAnalysis](https://gitlab.cern.ch/lhcb/MooreAnalysis) repository contains the `HltEfficiencyChecker` tool for giving rates and
efficiencies. To get `MooreAnalysis`, you can use the nightlies or do `make MooreAnalysis` from the top-level directory of the stack.

To get the efficiencies of all the Allen lines, from the top-level directory (`Allen_Gaudi_integration`) do:

```
MooreAnalysis/run MooreAnalysis/HltEfficiencyChecker/scripts/hlt_eff_checker.py MooreAnalysis/HltEfficiencyChecker/options/hlt1_eff_example.yaml
```

and to get the rates:

```
MooreAnalysis/run MooreAnalysis/HltEfficiencyChecker/scripts/hlt_eff_checker.py MooreAnalysis/HltEfficiencyChecker/options/hlt1_rate_example.yaml
```


Full documentation for the `HltEfficiencyChecker` tool, including a walk-through example for HLT1 efficiencies with Allen, is given 
[here](https://lhcbdoc.web.cern.ch/lhcbdoc/moore/master/tutorials/hltefficiencychecker.html).

