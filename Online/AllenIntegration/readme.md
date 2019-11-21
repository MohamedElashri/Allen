Setup Allen as Gaudi project
=============================

This readme explains how to setup Allen as Gaudi project, linking to libraries from Rec and using Brunel for the configuration, on lxplus.

```
source /cvmfs/lhcb.cern.ch/lib/LbEnv
```

Create a new directory and clone all of the `Rec`, `Brunel` and `Allen` repositories into this new directory. Call the folling commands in `Allen` and `Rec`.
```
lb-project-init
make configure
make install
```