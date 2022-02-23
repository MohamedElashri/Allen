###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
#[========================================[.rst:
Dumpers/RootDumpers
------------------
Utility algorithms to dump reconstructed objects
to ROOT files for development and debugging of
GPU algorithms
#]========================================]

gaudi_add_module(RootDumpers
                 SOURCES
                   src/PrTrackerDumper.cpp
                   src/DumpVeloUTState.cpp
                 LINK
                   Gaudi::GaudiAlgLib
                   LHCb::AssociatorsBase
                   LHCb::DAQEventLib
                   LHCb::DAQKernelLib
                   LHCb::LinkerEvent
                   LHCb::TrackEvent
                   LHCb::MCEvent
                   LHCb::RelationsLib
                   Rec::PrKernel
                   Boost::headers
                   BinaryDumpers
                   ROOT::Tree)

gaudi_add_tests(QMTest)
