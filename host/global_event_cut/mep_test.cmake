include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/backend/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/global_event_cut/include)
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
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/preprocessing/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/search_initial_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/find_compatible_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/triplet_seeding/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/triplet_keep_best/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/extend_tracks_x/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/composite_algorithms/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/extend_tracks_first_layers_x/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/extend_tracks_uv/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/quality_filters/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/fit/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/calculate_parametrization/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/consolidate/include)
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
include_directories(${CMAKE_SOURCE_DIR}/host/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/host/global_event_cut/include)
include_directories(${CMAKE_SOURCE_DIR}/host/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/pv/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/selections/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/device/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/device/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/vertex_fit/vertex_fitter/include)
include_directories(${CMAKE_SOURCE_DIR}/device/selections/Hlt1/include)
include_directories(${CMAKE_SOURCE_DIR}/external)
include_directories(${PROJECT_BINARY_DIR}/configuration/sequences)
include_directories(${CPPGSL_INCLUDE_DIR})
include_directories(${Boost_INCLUDE_DIRS})

# TODO: This test breaks CMake in Debug mode:

# [6/30] Linking CXX executable host/global_event_cut/mep_gec
# FAILED: host/global_event_cut/mep_gec 
# : && /cvmfs/sft.cern.ch/lcg/releases/clang/8.0.0-ed577/x86_64-centos7/bin/clang++  -Wall -Wextra -Wpedantic -Wnon-virtual-dtor -Wdouble-promotion -Wno-gnu-zero-variadic-macro-arguments -march=native -O3 -g -DNDEBUG   host/global_event_cut/CMakeFiles/mep_
# gec.dir/test/mep_gec.cpp.o host/global_event_cut/CMakeFiles/mep_gec.dir/__/__/backend/src/CPUBackend.cpp.o  -o host/global_event_cut/mep_gec  -Wl,-rpath,/cvmfs/sft.cern.ch/lcg/views/LCG_97python3/x86_64-centos7-clang8-opt/lib: libCommon.a mdf/libmdf.a ho
# st/global_event_cut/libHostGEC.a -L/cvmfs/sft.cern.ch/lcg/releases/LCG_97python3/./ROOT/v6.20.02/x86_64-centos7-clang8-opt/lib -lTree -lCore -lCling -lHist -lRIO -L/cvmfs/sft.cern.ch/lcg/views/LCG_97python3/x86_64-centos7-clang8-opt/lib -ltbb /cvmfs/sft.
# cern.ch/lcg/views/LCG_97python3/x86_64-centos7-clang8-opt/lib/libz.so -lstdc++fs backend/libBackend.a && :
# host/global_event_cut/libHostGEC.a(HostGlobalEventCut.cpp.o): In function `DoubleArgumentOverloadResolution<host_global_event_cut::Parameters::dev_event_list_t, host_global_event_cut::Parameters::host_event_list_t, ArgumentRefManager<std::tuple<host_glob
# al_event_cut::Parameters::host_ut_raw_banks_t&, host_global_event_cut::Parameters::host_ut_raw_offsets_t&, host_global_event_cut::Parameters::host_scifi_raw_banks_t&, host_global_event_cut::Parameters::host_scifi_raw_offsets_t&, host_global_event_cut::Pa
# rameters::host_total_number_of_events_t&, host_global_event_cut::Parameters::host_event_list_t&, host_global_event_cut::Parameters::host_number_of_selected_events_t&, host_global_event_cut::Parameters::dev_event_list_t&>, std::tuple<host_global_event_cut
# ::Parameters::host_ut_raw_banks_t, host_global_event_cut::Parameters::host_ut_raw_offsets_t, host_global_event_cut::Parameters::host_scifi_raw_banks_t, host_global_event_cut::Parameters::host_scifi_raw_offsets_t, host_global_event_cut::Parameters::host_t
# otal_number_of_events_t, host_global_event_cut::Parameters::host_event_list_t, host_global_event_cut::Parameters::host_number_of_selected_events_t, host_global_event_cut::Parameters::dev_event_list_t, host_global_event_cut::Parameters::min_scifi_ut_clust
# ers_t, host_global_event_cut::Parameters::max_scifi_ut_clusters_t>, host_global_event_cut::Parameters>, void>::copy(ArgumentRefManager<std::tuple<host_global_event_cut::Parameters::host_ut_raw_banks_t&, host_global_event_cut::Parameters::host_ut_raw_offs
# ets_t&, host_global_event_cut::Parameters::host_scifi_raw_banks_t&, host_global_event_cut::Parameters::host_scifi_raw_offsets_t&, host_global_event_cut::Parameters::host_total_number_of_events_t&, host_global_event_cut::Parameters::host_event_list_t&, ho
# st_global_event_cut::Parameters::host_number_of_selected_events_t&, host_global_event_cut::Parameters::dev_event_list_t&>, std::tuple<host_global_event_cut::Parameters::host_ut_raw_banks_t, host_global_event_cut::Parameters::host_ut_raw_offsets_t, host_g
# lobal_event_cut::Parameters::host_scifi_raw_banks_t, host_global_event_cut::Parameters::host_scifi_raw_offsets_t, host_global_event_cut::Parameters::host_total_number_of_events_t, host_global_event_cut::Parameters::host_event_list_t, host_global_event_cu
# t::Parameters::host_number_of_selected_events_t, host_global_event_cut::Parameters::dev_event_list_t, host_global_event_cut::Parameters::min_scifi_ut_clusters_t, host_global_event_cut::Parameters::max_scifi_ut_clusters_t>, host_global_event_cut::Paramete
# rs> const&, CUstream_st*)':
# /home/dcampora/projects/allen_velo/build_clang8/../stream/gear/include/ArgumentManager.cuh:316: undefined reference to `cudaMemcpyAsync'
# /home/dcampora/projects/allen_velo/build_clang8/../stream/gear/include/ArgumentManager.cuh:316: undefined reference to `cudaGetErrorString'
# clang-8: error: linker command failed with exit code 1 (use -v to see invocation)

# add_executable(mep_gec test/mep_gec.cpp ${CMAKE_SOURCE_DIR}/backend/src/CPUBackend.cpp)

# target_include_directories(mep_gec PUBLIC
#   ${CPPGSL_INCLUDE_DIR}
#   ${CMAKE_SOURCE_DIR}/stream/gear/include
#   ${CMAKE_SOURCE_DIR}/host/global_event_cut/include
#   ${CMAKE_SOURCE_DIR}/main/include
#   ${Boost_INCLUDE_DIRS})

# if (STANDALONE)
#   target_link_libraries(mep_gec PUBLIC Common mdf HostGEC ${MPI_CXX_LIBRARIES})
# else()
#   find_package(fmt REQUIRED)
#   target_link_libraries(mep_gec PUBLIC Common mdf HostGEC ${MPI_CXX_LIBRARIES} fmt::fmt)
# endif()

# target_compile_definitions(mep_gec PUBLIC TARGET_DEVICE_CPU)

# install(TARGETS mep_gec RUNTIME DESTINATION bin OPTIONAL)
