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
                   src/DumpVeloUTState.cpp
                 LINK
                   Gaudi::GaudiAlgLib
                   LHCb::DAQEventLib
                   LHCb::DAQKernelLib
                   LHCb::TrackEvent
                   LHCb::MCEvent
                   Rec::PrKernel
                   Boost::headers)

gaudi_add_tests(QMTest)
