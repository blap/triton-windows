# Check if MLIR is available by checking for a core MLIR target
if(TARGET MLIRSupport)
  set(MLIR_AVAILABLE TRUE)
else()
  set(MLIR_AVAILABLE FALSE)
endif()

if(MLIR_AVAILABLE)
  # Add build directory include paths for tablegen files first, ensuring they are searched before source paths
  # Use BEFORE keyword to ensure these paths are searched first
  include_directories(BEFORE ${CMAKE_BINARY_DIR}/third_party/nvidia/hopper/include)
  include_directories(BEFORE ${CMAKE_BINARY_DIR}/third_party/nvidia/include)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
  include_directories(${CMAKE_CURRENT_BINARY_DIR}/include)
  add_subdirectory(include)
  add_subdirectory(lib)
  
  # Build NVIDIA backend as a regular library instead of a plugin
  if(TRITON_BUILD_PYTHON_MODULE)
    add_library(TritonNVIDIA SHARED ${CMAKE_CURRENT_SOURCE_DIR}/triton_nvidia.cc)
    target_link_libraries(TritonNVIDIA PRIVATE 
      TritonNVIDIAGPUToLLVM 
      NVGPUToLLVM
      NVGPUIR
      NVWSIR
      NVWSTransforms
      NVHopperTransforms
      TritonIR
      TritonGPUIR
      TritonNvidiaGPUIR
      TritonGPUToLLVM
      TritonLLVMIR
      TritonAnalysis
      TritonTools
      TritonTransforms
      TritonGPUTransforms
      TritonNvidiaGPUTransforms
      MLIRUBToLLVM
      Python3::Module 
      pybind11::headers
      dlfcn
    )
    set_property(GLOBAL APPEND PROPERTY TRITON_LIBS TritonNVIDIA)
  endif()
  
  if(TRITON_BUILD_UT)
    add_subdirectory(unittest)
  endif()
  add_subdirectory(hopper)
else()
  message(STATUS "Skipping NVIDIA backend due to missing MLIR")
endif()