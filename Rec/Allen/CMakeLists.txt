################################################################################
# Package: Allen
################################################################################

include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/configuration/sequences)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/float_operations/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/binary_search/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/device/global_event_cut/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/UTDecoding/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/consolidate/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/compassUT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/calculate_phi_and_sort/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/consolidate_tracks/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/mask_clustering/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/search_by_triplet/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/simplified_kalman_filter/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/include)
include_directories(${CMAKE_SOURCE_DIR}/device/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/preprocessing/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/is_muon/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/classification/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/decoding_steps/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/patPV/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/raw_banks/include)
include_directories(${CMAKE_SOURCE_DIR}/host/velo/clustering/include)
include_directories(${CMAKE_SOURCE_DIR}/host/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/host/global_event_cut/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/pv/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/selections/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/device/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/device/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/vertex_fit/vertex_fitter/include)
include_directories(${CMAKE_SOURCE_DIR}/device/selections/Hlt1/include)

gaudi_subdir(Allen v1r0)

gaudi_depends_on_subdirs(Online/OnlineKernel
                         Det/FTDet
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
find_package(cppgsl REQUIRED)
find_package(Rangev3 REQUIRED)
find_package(ZMQ REQUIRED)

include_directories(SYSTEM ${Boost_INCLUDE_DIRS} ${CPPGSL_INCLUDE_DIR} ${RANGEV3_INCLUDE_DIR} ${GSL_INCLUDE_DIRS} "${PROJECT_BINARY_DIR}/configuration/sequences")

message(STATUS "Setting Allen install dir env variable to ${CMAKE_INSTALL_PREFIX}")
gaudi_env(SET ALLEN_INSTALL_DIR ${CMAKE_INSTALL_PREFIX})
 
gaudi_add_module(AllenWrapper
                 src/*.cpp
                 INCLUDE_DIRS Online/OnlineKernel
                 LINK_LIBRARIES AllenLib DAQEventLib DAQKernelLib GaudiAlgLib
                                PrKernel VPDetLib UTDetLib UTKernelLib
                                FTDetLib HltEvent)
if(CMAKE_BUILD_TYPE STREQUAL Debug)
  target_compile_definitions(AllenWrapper PRIVATE ALLEN_DEBUG)
endif()
target_compile_definitions(AllenWrapper PRIVATE ALLEN_DEBUG)

if(TARGET_DEVICE STREQUAL "CPU" OR TARGET_DEVICE STREQUAL "CUDACLANG")
  target_compile_definitions(AllenWrapper PRIVATE CPU)
endif()
