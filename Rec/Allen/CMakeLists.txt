################################################################################
# Package: Allen
################################################################################

include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/configuration/sequences)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/float_operations/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/binary_search/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/global_event_cut/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/UTDecoding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/consolidate/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/compassUT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/calculate_phi_and_sort/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/consolidate_tracks/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/mask_clustering/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/search_by_triplet/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/simplified_kalman_filter/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/preprocessing/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/classifiers/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/utils/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/search_initial_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/find_compatible_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/triplet_seeding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/triplet_keep_best/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/extend_tracks_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/composite_algorithms/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/extend_tracks_first_layers_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/extend_tracks_uv/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/quality_filters/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/fit/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/calculate_parametrization/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/consolidate/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/preprocessing/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/is_muon/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/classification/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/decoding_steps/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/patPV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/raw_banks/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/velo/clustering/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/global_event_cut/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/pv/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/selections/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/vertex_fit/vertex_fitter/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/selections/Hlt1/include)

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

include_directories(SYSTEM ${Boost_INCLUDE_DIRS} ${CPPGSL_INCLUDE_DIRS} ${RANGEV3_INCLUDE_DIR} ${GSL_INCLUDE_DIRS} "${PROJECT_BINARY_DIR}/configuration/sequences")

gaudi_add_module(AllenIntegration
                 src/*.cpp
                 INCLUDE_DIRS Online/OnlineKernel
                 LINK_LIBRARIES OnlineKernel AllenLib DAQEventLib DAQKernelLib GaudiAlgLib
                                PrKernel VPDetLib UTDetLib UTKernelLib
                                FTDetLib)
if(CMAKE_BUILD_TYPE STREQUAL Debug)
  target_compile_definitions(AllenIntegration PRIVATE ALLEN_DEBUG)
endif()
target_compile_definitions(AllenIntegration PRIVATE ALLEN_DEBUG)

if(TARGET_DEVICE STREQUAL "CPU")
  target_compile_definitions(AllenIntegration PRIVATE CPU)
endif()
