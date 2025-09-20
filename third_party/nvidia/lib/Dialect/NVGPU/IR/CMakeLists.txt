add_triton_library(NVGPUIR
  Dialect.cpp

  DEPENDS
  NVGPUTableGen
  NVGPUAttrDefsIncGen

  LINK_LIBS PUBLIC
  MLIRLLVMDialect
)

# Add the include directory where TableGen files are generated
# Use BEFORE to ensure the build directory is searched before the source directory
target_include_directories(NVGPUIR BEFORE PRIVATE
  ${CMAKE_CURRENT_BINARY_DIR}/../../../include
  ${CMAKE_CURRENT_SOURCE_DIR}/../../../include
)

# Ensure the specific NVGPU IR directory is included with build directory first
target_include_directories(NVGPUIR BEFORE PRIVATE
  ${CMAKE_CURRENT_BINARY_DIR}/../../../include/Dialect/NVGPU/IR
  ${CMAKE_CURRENT_SOURCE_DIR}/../../../include/Dialect/NVGPU/IR
)