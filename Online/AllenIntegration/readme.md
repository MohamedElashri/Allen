Setup Allen as Gaudi project, linked to Rec and Brunel
=============================

This readme explains how to setup Allen as Gaudi project, linking to libraries from Rec and using Brunel for the configuration, on lxplus.

```
source /cvmfs/lhcb.cern.ch/lib/LbEnv
```

Create a new directory `Allen_Gaudi_integration` and clone all of the `Rec`, `Brunel` and `Allen` repositories into this new directory. The directory should now contain the following sub-directories:
```
ls Allen_Gaudi_integration
Allen Brunel Rec

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
cd ..
cd Brunel
```

In Brunel, change `CMakeLists.txt` line 20 to `USE Allen	v0r7` and delete the `Rec` directory, then:
```
lb-project-init
make configure
make install
```

The calss to `lb-project-init` are only required when setting up the directories for the first time.

Adopt the day of the nightly build according to when you are building (Tue in the above example). Possibly check that the nightly build was successful.