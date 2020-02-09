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
# Package: RootDumpers
################################################################################
gaudi_subdir(RootDumpers v1r0)

gaudi_depends_on_subdirs(Event/TrackEvent
                         Event/DAQEvent
                         GaudiAlg
                         Pr/PrKernel)

find_package(Boost)
find_package(ROOT COMPONENTS Core)
include_directories(SYSTEM ${Boost_INCLUDE_DIRS} ${ROOT_INCLUDE_DIRS})

gaudi_add_module(RootDumpers
                 src/*.cpp
                 INCLUDE_DIRS Event/TrackEvent
                 LINK_LIBRARIES DAQEventLib DAQKernelLib GaudiAlgLib
                                PrKernel TrackEvent)

gaudi_add_test(QMTest QMTEST)
