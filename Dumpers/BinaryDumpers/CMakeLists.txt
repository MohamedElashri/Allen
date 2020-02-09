###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
################################################################################
# Package: BinaryDumpers
################################################################################
gaudi_subdir(BinaryDumpers v1r0)

gaudi_depends_on_subdirs(Det/FTDet
                         Det/VPDet
                         UT/UTDAQ
                         UT/UTKernel
                         Event/FTEvent
                         DAQ/DAQKernel
                         Event/DAQEvent
                         Event/DigiEvent
                         GaudiAlg
                         Pr/PrKernel
			 Muon/MuonID)

find_package(Boost REQUIRED)
find_package(Rangev3 REQUIRED)
find_package(ROOT COMPONENTS Core)
include_directories(SYSTEM ${Boost_INCLUDE_DIRS} ${ROOT_INCLUDE_DIRS} ${Rangev3_INCLUDE_DIRS})

gaudi_install_headers(Dumpers)

gaudi_add_library(BinaryDumpersLib
                  NO_PUBLIC_HEADERS
                  src/lib/*.cpp
                  INCLUDE_DIRS Event/FTEvent Pr/PrPixel Muon/MuonID
                  LINK_LIBRARIES DAQEventLib DAQKernelLib GaudiAlgLib
                                 PrKernel VPDetLib UTDetLib UTKernelLib
                                 FTDetLib MuonDAQLib)

gaudi_add_module(BinaryDumpers
                 src/*.cpp
                 INCLUDE_DIRS Event/FTEvent Det/VPDet Muon/MuonID
                 LINK_LIBRARIES DAQEventLib DAQKernelLib GaudiAlgLib
                                PrKernel VPDetLib UTDetLib UTKernelLib
                                FTDetLib MuonDAQLib)

gaudi_add_test(QMTest QMTEST)
