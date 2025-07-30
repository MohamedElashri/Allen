.. _where_to_develop_for_gpus:

Where to develop for GPUs
===========================

For development purposes, a server with eight GeForce RTX 2080 Ti GPUs is set up in the CERN network.
Dedicated account is required, for requesting account please contact RTA WP5 coordinators.
The development server is reachable from lxplus like this:

  ssh lbgpudev01

Upon login, a GPU will be automatically assigned to you.
This machine is dedicated for GPU-related developments and should not be used for CPU-only work.
Various Allen input data is available on `/eos/` and listed in the TestFileDB: https://gitlab.cern.ch/lhcb-datapkg/PRConfig/-/blob/master/python/PRConfig/TestFileDB.py
