Call Allen from Gaudi, event loop directed by Brunel or Moore
=============================

This readme explains how to setup Allen as Gaudi project, calling Allen either from Brunel or Moore. This means that Allen is called one event at a time and the event loop is governed by Brunel or Moore.
The described setup works on lxplus.

```
LbLogin -c x86_64-centos7-gcc9-opt
```

If a specific version of [Rec](https://gitlab.cern.ch/lhcb/Rec) is needed, Rec needs to be compiled as well. If not, you can skip these instructions and use Rec from the nightlies instead.
If https://gitlab.cern.ch/lhcb/Rec/merge_requests/1897 is not yet merged, checkout that branch in Rec.

Create a new directory `Allen_Gaudi_integration` and clone both `Allen` and `Rec` into this new directory. 
```
ls Allen_Gaudi_integration
Allen Rec

```

```
export CMAKE_PREFIX_PATH=/cvmfs/lhcbdev.cern.ch/nightlies/lhcb-head/Tue/:$CMAKE_PREFIX_PATH
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

Call the executable from within the Moore directory:
```
./build.x86_64-centos7-gcc9-opt/run gaudirun.py Hlt/Moore/tests/options/default_input_and_conds_hlt1.py Hlt/RecoConf/options/hlt1_reco_baseline_and_Allen_with_mcchecking.py
```
This will run both the baseline HLT1 reconstruction sequence and Allen. It will call the MC checkers for track reconstruction efficiencies and PV reconstruction efficiencies and resolutions.

To check the IP resolution:
```
./build.x86_64-centos7-gcc9-opt/run gaudirun.py Hlt/Moore/tests/options/default_input_and_conds_hlt1.py Hlt/RecoConf/options/hlt1_reco_allen_IPresolution.py
```
To check the track resolution:
```
./build.x86_64-centos7-gcc9-opt/run gaudirun.py Hlt/Moore/tests/options/default_input_and_conds_hlt1.py Hlt/RecoConf/options/hlt1_reco_allen_trackresolution.py
```


