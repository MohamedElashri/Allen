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
                   src/AllenReportsToRawEvent.cpp
                   src/AllenForwardToV2Tracks.cpp
                   src/AllenPVsToRecVertexV2.cpp
                   src/TestVeloClusters.cpp
                   src/AllenUTToV2Tracks.cpp
                   src/AllenVeloToV2Tracks.cpp
                   src/RunAllen.cpp
                   src/TestAllenCaloDigits.cpp
                   src/TestUTHits.cpp
                   src/ProvideConstants.cpp
                   src/ProvideRuntimeOptions.cpp
                 LINK
                   AllenLib
                   EventModel
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

gaudi_add_module(AllenAlgorithms
                 SOURCES
                   ${WRAPPED_ALGORITHM_SOURCES}
                 LINK
                   AllenLib
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
add_dependencies(AllenAlgorithms gaudi_wrappers_of_allen_algorithms)

if(CMAKE_BUILD_TYPE MATCHES Debug)
  target_compile_definitions(AllenWrapper PRIVATE ALLEN_DEBUG)
endif()
target_compile_definitions(AllenWrapper PRIVATE -D${TARGET_DEFINITION})
target_compile_definitions(AllenAlgorithms PRIVATE -D${TARGET_DEFINITION})

gaudi_install(PYTHON)

gaudi_add_tests(QMTest)
