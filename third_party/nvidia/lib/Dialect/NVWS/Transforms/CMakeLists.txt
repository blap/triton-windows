# Create NVWSTransforms as a static library instead of an object library
add_library(NVWSTransforms STATIC
  LowerAref.cpp
  LowerWarpGroup.cpp
)

# Add dependencies
add_dependencies(NVWSTransforms NVWSTransformsIncGen)

# Link libraries
target_link_libraries(NVWSTransforms PUBLIC
  TritonIR
  TritonGPUIR
  TritonNvidiaGPUIR
  NVWSIR
  MLIRTransformUtils
)

# Add include directories for NVWS Transforms
target_include_directories(NVWSTransforms PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/../../../include
  ${CMAKE_CURRENT_BINARY_DIR}/../../../include
  ${CMAKE_CURRENT_SOURCE_DIR}/../../include/Dialect/NVWS/Transforms
  ${CMAKE_CURRENT_BINARY_DIR}/../../include/Dialect/NVWS/Transforms
)