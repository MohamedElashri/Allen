###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
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
                   src/GaudiAllenPVsToRecVertexV2.cpp
                   src/GaudiAllenUTToV2Tracks.cpp
                   src/GaudiAllenCaloToCaloClusters.cpp
                   src/GaudiAllenCountAndDumpLineDecisions.cpp
                   src/GaudiAllenForwardToV2Tracks.cpp
                   src/GaudiAllenReportsToRawEvent.cpp
                   src/GaudiAllenSVsToRecVertexV2.cpp
                   src/GaudiAllenVeloToV2Tracks.cpp
                   src/ProvideConstants.cpp
                   src/ProvideRuntimeOptions.cpp
                   src/TestAllenCaloDigits.cpp
                   src/TestUTHits.cpp
                   src/TestVeloClusters.cpp
                 LINK
                   AllenLib
		   Backend
    		   Stream
   		   HostCommon
   		   HostEventModel
    		   NonEventData
    		   TrackChecking
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
                   Gaudi::GaudiAlgLib
                   LHCb::DAQEventLib
                   LHCb::DAQKernelLib
                   LHCb::VPDetLib
                   LHCb::UTDetLib
                   LHCb::UTKernelLib
                   LHCb::CaloDetLib
                   LHCb::FTDetLib
                   LHCb::HltDAQLib
                   LHCb::MCEvent
                   Rec::PrKernel)

target_include_directories(AllenWrapper PRIVATE ${PROJECT_BINARY_DIR}/code_generation)
add_dependencies(AllenWrapper struct_to_tuple)

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
           Stream
         HostCommon
         HostEventModel
           NonEventData
           TrackChecking
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
       WrapperInterface
                   Gaudi::GaudiAlgLib
                   LHCb::DAQEventLib
                   LHCb::DAQKernelLib
                   LHCb::VPDetLib
                   LHCb::UTDetLib
                   LHCb::UTKernelLib
                   LHCb::CaloDetLib
                   LHCb::FTDetLib
                   LHCb::HltDAQLib
                   LHCb::MCEvent
                   Rec::PrKernel)

target_include_directories(AllenAlgorithms PRIVATE Allen)
add_custom_target(gaudi_wrappers_of_allen_algorithms DEPENDS ${WRAPPED_ALGORITHM_SOURCES})
target_include_directories(AllenAlgorithms PRIVATE ${PROJECT_BINARY_DIR}/code_generation)
add_dependencies(AllenAlgorithms gaudi_wrappers_of_allen_algorithms struct_to_tuple)
target_compile_definitions(AllenAlgorithms PRIVATE -D${TARGET_DEFINITION})

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
