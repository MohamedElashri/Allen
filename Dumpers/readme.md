Produce MDF input for standalone Allen 
================================

These are instructions for how to produce MDF files for Allen standalone running by running Moore. The MDF files will contain raw banks with the raw data from the sub-detectors and raw banks containing MC information about tracks and vertices required for the physics checks inside Allen.


Follow [these](../Rec/Allen/readme.md) instruction to call Allen from Moore. Then use this [options script](https://gitlab.cern.ch/lhcb/Moore/blob/master/Hlt/RecoConf/options/mdf_for_standalone_Allen.py) to dump both an MDF file
and the geometry information required for standalone Allen processing. The easiest is to use as input files from the TestFileDB, then only the key has to be specified. The output will be located in a directory, whose name is the TestFileDB key. This directory will contain two subdirectories: `mdf` with the MDF file containing the raw banks and `geometry_dddb-tag_sim-tag` with binary files containing the geometry information required for Allen. 
Call the script in a stack setup like so:
```
./Moore/run gaudirun.py Moore/Hlt/RecoConf/options/mdf_for_standalone_Allen.py
```

If you would like to dump a large amount of events into MDF files, it is convenient to produce several MDF output files to avoid too large single files. This [python script](https://gitlab.cern.ch/lhcb/Moore/-/blob/master/Hlt/RecoConf/options/mdf_split_for_standalone_Allen.py) produces several MDF output files from the input files. Again, the TestFileDB entry is used to specify the input. The output MDF files combine a number of input files, configurable with `n_files_per_chunk`. Call this script like so:
```
./Moore/run bash --norc
python Moore/Hlt/RecoConf/options/mdf_split_for_standalone_Allen.py
```

    
    
    
