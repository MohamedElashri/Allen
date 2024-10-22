###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
#[========================================[.rst:
Rec/Allen
------------------
Utility algorithms to run the Allen
sequence as part of a Gaudi/LHCb
application
#]========================================]

include(GenerateConfiguration)

gaudi_add_module(AllenWrapper
                 SOURCES
                   src/GaudiAllenPVsToPrimaryVertexContainer.cpp
                   src/GaudiAllenCaloToCaloClusters.cpp
                   src/GaudiAllenCountAndDumpLineDecisions.cpp
                   src/GaudiAllenFilterEventsLineDecisions.cpp
                   src/GaudiAllenReportsToRawEvent.cpp
                   src/GaudiAllenLumiSummaryToRawEvent.cpp
                   src/GaudiAllenSVsToRecVertexV2.cpp
                   src/GaudiAllenTrackViewsToV3Tracks.cpp
                   src/AllenROOTService.cpp
                   src/ProvideRuntimeOptions.cpp
                   src/CompareRecAllenCaloDigits.cpp
                   src/CompareRecAllenMuonHits.cpp
                   src/CompareRecAllenUTHits.cpp
                   src/GaudiAllenTransformAllenRecUTHits.cpp
                   src/MCCheckRecAllenUTHits.cpp
                   src/CompareRecAllenFTClusters.cpp
                   src/CompareRecAllenVPHits.cpp
                   src/TestVeloClusters.cpp
                   src/TestAllenRichPixels.cpp
                   src/IOMonitor.cpp
                 LINK
                   AllenLib
                   Backend
                   Stream
                   HostCommon
                   HostEventModel
                   HostRoutingBits
                   TrackChecking
                   PV_beamline
                   PVChecking
                   CheckClustering
                   SelChecking
                   Monitoring
                   HostCombiners
                   EventModel
                   Gear
                   mdf
                   LHCbEvent
                   EventModel
                   MuonCommon
                   EventModel
                   Gear
                   Rich
                   Gaudi::GaudiAlgLib
                   LHCb::DAQEventLib
                   LHCb::RecEvent
                   LHCb::VPDetLib
                   LHCb::UTDetLib
                   LHCb::UTKernelLib
                   LHCb::CaloDetLib
                   LHCb::FTDetLib
                   LHCb::MCEvent
                   LHCb::RecEvent
                   LHCb::RichFutureUtils
                   Rec::PrKernel)

target_include_directories(AllenWrapper PRIVATE ${PROJECT_BINARY_DIR}/code_generation)

if(CMAKE_BUILD_TYPE MATCHES Debug)
  target_compile_definitions(AllenWrapper PRIVATE ALLEN_DEBUG)
endif()
target_compile_definitions(AllenWrapper PRIVATE -D${TARGET_DEFINITION})

if(TARGET_DEVICE STREQUAL "CPU")
gaudi_add_module(AllenAlgorithms
                 SOURCES
                   ${WRAPPED_ALGORITHM_SOURCES}
                 LINK
                   AllenLib
                   Backend
                   CheckClustering
                   EventModel
                   Gear
                   HostCombiners
                   HostCommon
                   HostEventModel
                   HostRoutingBits
                   LHCbEvent
                   Monitoring
                   MuonCommon
                   NonEventData
                   PV_beamline
                   PVChecking
                   SelChecking
                   SelectionsHeaders
                   Stream
                   TrackChecking
                   UTCommon
                   Utils
                   WrapperInterface
                   mdf
                   Rich
                   Gaudi::GaudiAlgLib
                   LHCb::DAQEventLib
                   LHCb::VPDetLib
                   LHCb::UTDetLib
                   LHCb::UTKernelLib
                   LHCb::CaloDetLib
                   LHCb::FTDetLib
                   LHCb::MCEvent
                   Rec::PrKernel)

target_include_directories(AllenAlgorithms PRIVATE Allen)
add_custom_target(gaudi_wrappers_of_allen_algorithms DEPENDS ${WRAPPED_ALGORITHM_SOURCES})
target_include_directories(AllenAlgorithms PRIVATE ${PROJECT_BINARY_DIR}/code_generation)
add_dependencies(AllenAlgorithms gaudi_wrappers_of_allen_algorithms)
target_compile_definitions(AllenAlgorithms PRIVATE -D${TARGET_DEFINITION})
# We cannot fix use of lambda capture `[=]` (C++17) or `[=,this]` (C++20) at the same time
# so we hide the warning when we use C++17.
target_compile_options(AllenAlgorithms PRIVATE -Wno-c++20-extensions)

endif()

gaudi_install(PYTHON)

gaudi_add_tests(QMTest)

gaudi_add_executable(test_mass_definitions
    SOURCES
        tests/src/test_mass_definitions.cpp
    LINK
        Boost::unit_test_framework
        AllenLib
        LHCb::LHCbKernel
        LHCb::PartPropLib
    TEST
)

if(BUILD_TESTING AND NOT USE_DD4HEP)
    # Disable test on data for detdesc builds
    set_property(
        TEST
          Allen.mdf_input_2023_data
          Allen.mdf_input_2024_data_tae
        PROPERTY
          DISABLED TRUE
    )
endif()
