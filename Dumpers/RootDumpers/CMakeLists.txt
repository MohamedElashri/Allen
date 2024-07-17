###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
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
                   LHCb::LinkerEvent
                   LHCb::TrackEvent
                   LHCb::MCEvent
                   LHCb::RelationsLib
                   Rec::PrKernel
                   Boost::headers
                   BinaryDumpers
                   ROOT::Tree)

gaudi_add_tests(QMTest)
