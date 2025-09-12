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
  
  # Add MLIR and LLVM include directories
  include_directories(${MLIR_INCLUDE_DIRS})
  include_directories(${LLVM_INCLUDE_DIRS})
  
  # Add Windows SDK and Visual Studio C++ include paths for Windows build
  if(WIN32)
    # Find Visual Studio installation
    set(VS_PATH "C:/Program Files/Microsoft Visual Studio/2022/Community")
    if(EXISTS ${VS_PATH})
      # Find the latest MSVC version
      file(GLOB MSVC_VERSIONS "${VS_PATH}/VC/Tools/MSVC/*")
      list(REVERSE MSVC_VERSIONS)
      list(GET MSVC_VERSIONS 0 LATEST_MSVC)
      
      if(EXISTS ${LATEST_MSVC})
        # Add Visual Studio C++ headers
        include_directories("${LATEST_MSVC}/include")
        include_directories("${LATEST_MSVC}/atlmfc/include")
        
        # Find Windows SDK
        file(GLOB WIN_SDK_VERSIONS "C:/Program Files (x86)/Windows Kits/10/Include/*")
        list(REVERSE WIN_SDK_VERSIONS)
        list(GET WIN_SDK_VERSIONS 0 LATEST_WIN_SDK)
        
        if(EXISTS ${LATEST_WIN_SDK})
          # Add Windows SDK headers
          include_directories("${LATEST_WIN_SDK}/ucrt")
          include_directories("${LATEST_WIN_SDK}/um")
          include_directories("${LATEST_WIN_SDK}/shared")
          include_directories("${LATEST_WIN_SDK}/winrt")
          include_directories("${LATEST_WIN_SDK}/cppwinrt")
        endif()
      endif()
    endif()
    
    # Add MLIR and Triton include paths for proper header resolution
    include_directories(${CMAKE_SOURCE_DIR}/include)
    include_directories(${CMAKE_BINARY_DIR}/include)
    include_directories(${CMAKE_SOURCE_DIR}/lib)
    include_directories(${CMAKE_SOURCE_DIR}/third_party)
  endif()
  
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