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

Testing Allen algorithms in Gaudi
---------------------------------

To test Allen algorithms in Gaudi, the data produced by an Allen
algorithm must be copied from memory managed by Allen's memory manager
to a members of the `HostBuffers` object. The `HostBuffers` will be
put in the TES by the `RunAllen` algorithm that wraps the entire Allen
sequence.

An example for the Velo clusters can be seen
[here](https://gitlab.cern.ch/lhcb/Allen/-/blob/raaij_decoding_tests/stream/sequence/include/HostBuffers.cuh#L59)
and [here](https://gitlab.cern.ch/lhcb/Allen/-/blob/raaij_decoding_tests/device/velo/mask_clustering/src/MaskedVeloClustering.cu#L49),
where additional members have been added to the `HostBuffers` and data
produced by the `velo_masked_clustering` algorithm is copied there.

The `TestVeloClusters` algorithm implements an example algorithm that
recreates the required Allen event model object - in this case
`Velo::ConstClusters` - from the data in `HostBuffers` and loops over
the clusters.

An example options file to run `TestVeloClusters` as a test can be
found [here](https://gitlab.cern.ch/lhcb/Moore/-/blob/master/Hlt/RecoConf/tests/qmtest/decoding.qms/hlt1_velo_decoding.qmt).


Future Developments for tests
------

Developments are ongoing to allow Allen algorithms to be directly run
as Gaudi algorithms through automatically generated wrappers. All data
produced by Allen algorithm will then be directly stored in the TES
when running with the CPU backend. The following merge requests tracks
the work in progress:
[https://gitlab.cern.ch/lhcb/Allen/-/merge_requests/431](https://gitlab.cern.ch/lhcb/Allen/-/merge_requests/431)

Once that work is completed and merged, Allen algorithms will no
longer need to copy data into the `HostBuffers` object and any Gaudi
algorithms used for testing will have to be updated to obtain their
data directly from the TES instead of from `HostBuffers`.
