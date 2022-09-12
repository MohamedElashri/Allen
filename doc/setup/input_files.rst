.. _input_files:

Input files
===============

Standalone Allen
^^^^^^^^^^^^^^^^^^^^
When running Allen standalone, MDF files are used as input. They contain the sub-detector raw-data and can also contain MC information. Since the LHCb conditions data base cannot be accessed during standalone processing, the geometry information required for HLT1 algorithms is written in binary format for the data base tags of the corresponding MDF file.

For various samples, MDF files and the corresponding geometry information have been produced and are available here:

  /eos/lhcb/wg/rta/WP6/Allen/mdf_input/

With lhcb/Allen!655, the default sequence uses Retina clusters for VELO tracking. MDF samples containing Retina clusters are available here:

  /eos/lhcb/wg/rta/WP6/Allen/mdf_input/RetinaCluster_samples_v1/

The directory name corresponds to the TestFileDB key of the sample. Some of these files have also been copied to the GPU development server (see :ref:`where_to_develop_for_gpus`), because they are used in the nightly CI tests. These can be found here:

  /scratch/allen_data/mdf_input/

If other inputs are required, follow these instructions: `Produce MDF files for standalone Allen`_. The same instructions explain also how to add Retina clusters to existing (X)DIGI files.

As Gaudi project, event loop steered by Moore (offline)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
When running allen :ref:`run_allen_in_gaudi_moore_eventloop`, any file type possible for Moore processing can be used (for example DIGI, XDIGI, MDF).


As Gaudi project, event loop steered by Allen (data-taking)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
MEP files are used when running Allen :ref:`run_allen_in_gaudi_allen_eventloop`.
MEP is the format produced by the event building, where the raw banks for several thousand events are written consecutively. These are typically data files, but can also be produced with a conversion tool from MDF files.

For development purposes, MDF files can also be used when running as a Gaudi project and steering the event loop from Allen.

Produce MDF files for standalone Allen
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
MDF files for Allen standalone running are produced by running Moore. The MDF files will contain raw banks with the raw data from the sub-detectors and raw banks containing MC information about tracks and vertices required for the physics checks inside Allen.
The easiest is to use as input files from the TestFileDB, then only the key has to be specified. The output will be located in a directory, whose name is the TestFileDB key. This directory will contain two subdirectories: `mdf` with the MDF file containing the raw banks and `geometry_dddb-tag_sim-tag` with binary files containing the geometry information required for Allen.
Call Moore in a _stack_setup like so::

  ./Moore/run gaudirun.py Moore/Hlt/RecoConf/options/mdf_for_standalone_Allen_retinacluster.py

If you would like to dump a large amount of events into MDF files, it is convenient to produce several MDF output files to avoid too large single files. A special script is provided for this use case. Again, the TestFileDB entry is used to specify the input. The output MDF files combine a number of input files, configurable with `n_files_per_chunk`::

  ./Moore/run gaudirun.py Moore/Hlt/RecoConf/scripts/mdf_split_for_standalone_Allen_retinacluster.py
  
Variants of the previous two scripts are also available to run without RetinaClusters (`mdf_for_standalone_Allen.py` and `mdf_split_for_standalone_Allen_retinacluster.py`).

DIGI files containing RetinaClusters
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Starting from Boole v43, centrally-produced DIGI files contain RetinaClusters by default.
DIGI files containing RetinaClusters are also available here:

  /eos/lhcb/wg/rta/WP6/Allen/digi_input/RetinaCluster_samples_v1/

These files can be called within option files using the corresponding entries in the TestFileDB.

How to add RetinaClusters to existing DIGI files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
To add RetinaClusters to a (X)DIGI file call Moore in a _stack_setup like so::

  ./Moore/run gaudirun.py Moore/Hlt/Moore/tests/options/input_add_retina_clusters.py Moore/Hlt/RecoConf/options/add_retina_clusters_to_digi.py

Input (X)DIGI files, together with their DDDB and CondDB tags, should be specified within `input_add_retina_clusters.py`.
In the same option file an appropriate name for the output (X)DIGI file containing RetinaClusters should also be specified.
Starting from an (X)DIGI file containing RetinaClusters, the corresponding MDF file can be obtained with the `mdf_for_standalone_Allen_retinacluster.py` script.

Run Allen without RetinaClusters
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
If XDIGI or MDF input files containing RetinaClusters are not available for a specific use case or RetinaCluster cannot be added to pre-existing files, it is still possible to run the reconstruction using the `hlt1_pp_veloSP` sequence.
This sequence performs VELO clustering within Allen, not requiring the VPRetinaCluster RawBank to be present in the input file.
When running Allen within Gaudi the switch from RetinaClusters to VeloSP can be done using the following lines::

  from AllenConf.velo_reconstruction import decode_velo
    
  with decode_velo.bind(retina_decoding=False):
    #call reconstruction as before
