include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)


file(GLOB x86MuonDecoding_cpp "src/*cpp")

add_library(x86MuonDecoding STATIC
        ${x86MuonDecoding_cpp}
)

set_property(TARGET x86MuonDecoding PROPERTY
             CUDA_SEPARABLE_COMPILATION ON)

if ( ROOT_FOUND )
    target_compile_definitions(x86MuonDecoding PUBLIC WITH_ROOT)
    target_include_directories(x86MuonDecoding BEFORE PRIVATE ${ROOT_INCLUDE_DIRS})
endif()
