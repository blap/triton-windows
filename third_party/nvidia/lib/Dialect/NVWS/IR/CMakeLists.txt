add_triton_library(NVWSIR
  Dialect.cpp
  Ops.cpp

  DEPENDS
  NVWSTableGen
  NVWSAttrDefsIncGen

  LINK_LIBS PUBLIC
  TritonIR
  TritonGPUIR
)

# Add include directories for NVWS IR
target_include_directories(NVWSIR PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/../../include/Dialect/NVWS/IR
  ${CMAKE_CURRENT_BINARY_DIR}/../../include/Dialect/NVWS/IR
)