# Check if MLIR is available by checking for a core MLIR target
# If MLIR is not available, try to use fallback paths
if(TARGET MLIRSupport)
  set(MLIR_AVAILABLE TRUE)
else()
  # Check if we have the necessary MLIR headers in fallback paths
  if(EXISTS "${CMAKE_SOURCE_DIR}/llvm-project/mlir/include/mlir/Pass/Pass.h")
    set(MLIR_AVAILABLE TRUE)
    message(STATUS "Using fallback MLIR headers for NVIDIA backend")
    # Set up include directories for fallback MLIR
    include_directories("${CMAKE_SOURCE_DIR}/llvm-project/mlir/include")
    include_directories("${CMAKE_SOURCE_DIR}/llvm-project/llvm/include")
  else()
    set(MLIR_AVAILABLE FALSE)
  endif()
endif()

if(MLIR_AVAILABLE)
  # Add build directory include paths for tablegen files first, ensuring they are searched before source paths
  # Use BEFORE keyword to ensure these paths are searched first
  include_directories(BEFORE ${CMAKE_BINARY_DIR}/third_party/nvidia/hopper/include)
  include_directories(BEFORE ${CMAKE_BINARY_DIR}/third_party/nvidia/include)
  include_directories(BEFORE ${CMAKE_CURRENT_SOURCE_DIR}/include)
  include_directories(BEFORE ${CMAKE_CURRENT_BINARY_DIR}/include)
  
  # Add MLIR and LLVM include directories
  include_directories(${MLIR_INCLUDE_DIRS})
  include_directories(${LLVM_INCLUDE_DIRS})
  # Add Triton include directories
  include_directories(${CMAKE_SOURCE_DIR}/include)
  
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
  endif()
  
  # Add subdirectories in the correct order to ensure TableGen files are generated
  # Process include directory first to generate TableGen files
  add_subdirectory(include)
  
  # Process lib directory after include to ensure TableGen files are available
  add_subdirectory(lib)
  
  # Build NVIDIA backend as a static library to avoid symbol conflicts
  # This is a key fix for the Windows build - using STATIC instead of SHARED
  if(TRITON_BUILD_PYTHON_MODULE)
    add_library(TritonNVIDIA STATIC ${CMAKE_CURRENT_SOURCE_DIR}/triton_nvidia.cc)
    target_link_libraries(TritonNVIDIA PRIVATE 
      Python3::Module 
      pybind11::headers
      # Link dlfcn-win32 for Windows dynamic loading support
      dlfcn
      # Link NVWSTransforms to resolve NVWS pass symbols
      # Fix for double .lib extension issue - link directly with the target
      NVWSTransforms
    )
    
    # Add specific include directories for TableGen files with build directory first
    target_include_directories(TritonNVIDIA BEFORE PRIVATE
      ${CMAKE_BINARY_DIR}/third_party/nvidia/include
      ${CMAKE_CURRENT_SOURCE_DIR}/include
      ${CMAKE_BINARY_DIR}/third_party/nvidia/hopper/include
      ${CMAKE_CURRENT_SOURCE_DIR}/hopper/include
    )
    
    # Set the output directory for the static library
    set_target_properties(TritonNVIDIA PROPERTIES
      ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/Release
      LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/Release
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