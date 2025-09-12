cmake_minimum_required(VERSION 3.20)

if(POLICY CMP0116)
# Introduced in cmake 3.20
# https://cmake.org/cmake/help/latest/policy/CMP0116.html
  cmake_policy(SET CMP0116 OLD)
endif()

include(ExternalProject)

set(CMAKE_CXX_STANDARD 17)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

project(triton CXX C)
include(CTest)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Options - Windows build configuration
# Changed default values for Windows build optimization
option(TRITON_BUILD_BINARY "Build C++ Triton binaries" OFF)
option(TRITON_BUILD_PYTHON_MODULE "Build Python Triton bindings" ON)
option(TRITON_BUILD_PROTON "Build the Triton Proton profiler" OFF)
# Disabled unit tests and ccache by default for Windows build simplification
option(TRITON_BUILD_UT "Build C++ Triton Unit Tests" OFF)
option(TRITON_BUILD_WITH_CCACHE "Build with ccache (if available)" OFF)
# Allow disabling backends
option(TRITON_DISABLE_NVIDIA_BACKEND "Disable NVIDIA backend" OFF)

# Set default backends if not specified
if(NOT DEFINED TRITON_CODEGEN_BACKENDS)
  if(NOT TRITON_DISABLE_NVIDIA_BACKEND)
    set(TRITON_CODEGEN_BACKENDS "nvidia")
  else()
    set(TRITON_CODEGEN_BACKENDS "")
  endif()
endif()

if(TRITON_BUILD_WITH_CCACHE)
  find_program(CCACHE_PROGRAM ccache)
  if(CCACHE_PROGRAM)
    set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}"
        CACHE STRING "C compiler launcher")
    set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}"
        CACHE STRING "CXX compiler launcher")
  else()
    message(
      STATUS
        "Could not find ccache. Consider installing ccache to speed up compilation."
    )
  endif()
endif()

set(TRITON_PARALLEL_LINK_JOBS "" CACHE STRING
  "Define the maximum number of concurrent link jobs (Ninja only).")
if (TRITON_PARALLEL_LINK_JOBS)
    set_property(GLOBAL APPEND PROPERTY JOB_POOLS link_job_pool=${TRITON_PARALLEL_LINK_JOBS})
    set(CMAKE_JOB_POOL_LINK link_job_pool)
endif()


# Ensure Python3 vars are set correctly
# used conditionally in this file and by lit tests

# Customized release build type with assertions: TritonRelBuildWithAsserts
set(CMAKE_C_FLAGS_TRITONRELBUILDWITHASSERTS "/O2")
set(CMAKE_CXX_FLAGS_TRITONRELBUILDWITHASSERTS "/O2 /std:c++17 /Zc:__cplusplus")

# Default build type
if(NOT CMAKE_BUILD_TYPE)
  message(STATUS "Default build type: Release")
  set(CMAKE_BUILD_TYPE "Release")
endif()


if(TRITON_BUILD_UT)
  # This is an aggregate target for all unit tests.
  add_custom_target(TritonUnitTests)
  set_target_properties(TritonUnitTests PROPERTIES FOLDER "Triton/Tests")
  include(AddTritonUnitTest)
endif()

# Compiler flags
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /nologo /bigobj /Zc:__STDC__ /Zc:preprocessor /permissive- /utf-8 /std:c++17 /Zc:__cplusplus")

# Add additional include directories for proper header resolution
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/third_party/nvidia/include)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/third_party/nvidia/include)

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

# Add library directories for Windows builds
if(WIN32)
  if(DEFINED CMAKE_LIBRARY_PATH)
    # Split the library paths and add them
    string(REPLACE ";" "\\\\;" LIB_PATHS "${CMAKE_LIBRARY_PATH}")
    foreach(LIB_PATH ${LIB_PATHS})
      link_directories("${LIB_PATH}")
    endforeach()
  endif()
  
  # Explicitly add common Windows library paths
  link_directories("C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.44.35207/lib/x64")
  link_directories("C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/um/x64")
  link_directories("C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/ucrt/x64")
endif()


# #########
# LLVM
# #########
# Check if MLIR_DIR is set as environment variable
if(DEFINED ENV{MLIR_DIR})
  set(MLIR_DIR $ENV{MLIR_DIR})
elseif(NOT MLIR_DIR)
  # Check if LLVM_DIR is set as environment variable
  if(DEFINED ENV{LLVM_DIR})
    set(LLVM_DIR $ENV{LLVM_DIR})
  endif()
  set(MLIR_DIR ${LLVM_DIR}/cmake/mlir)
endif()

# MLIR
find_package(MLIR REQUIRED CONFIG PATHS ${MLIR_DIR})

# LLVM
if(NOT DEFINED LLVM_DIR)
  if(DEFINED ENV{LLVM_DIR})
    set(LLVM_DIR $ENV{LLVM_DIR})
  endif()
endif()

find_package(LLVM REQUIRED CONFIG PATHS ${LLVM_DIR})

list(APPEND CMAKE_MODULE_PATH "${MLIR_CMAKE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")

# Debug: Print MLIR and LLVM directories
message(STATUS "MLIR_DIR: ${MLIR_DIR}")
message(STATUS "LLVM_DIR: ${LLVM_DIR}")
message(STATUS "MLIR_INCLUDE_DIRS: ${MLIR_INCLUDE_DIRS}")
message(STATUS "LLVM_INCLUDE_DIRS: ${LLVM_INCLUDE_DIRS}")

include(TableGen) # required by AddMLIR
include(AddLLVM)
include(AddMLIR)

# Utilities
function(add_triton_object name)
  cmake_parse_arguments(ARG "" "" "DEPENDS;LINK_LIBS" ${ARGN})
  add_library(${name} OBJECT)
  target_sources(${name}
    PRIVATE ${ARG_UNPARSED_ARGUMENTS}
    INTERFACE $<TARGET_OBJECTS:${name}>
  )


  # add_library(${name} OBJECT ${ARG_UNPARSED_ARGUMENTS})
  if(ARG_DEPENDS)
    add_dependencies(${name} ${ARG_DEPENDS})
  endif()
  if(ARG_LINK_LIBS)
    target_link_libraries(${name} PUBLIC ${ARG_LINK_LIBS})
  endif()
endfunction(add_triton_object)

set_property(GLOBAL PROPERTY TRITON_LIBS "")
function(add_triton_library name)
  set_property(GLOBAL APPEND PROPERTY TRITON_LIBS ${name})
  add_triton_object(${name} ${ARGN})
  llvm_update_compile_flags(${name})
endfunction()

set_property(GLOBAL PROPERTY TRITON_PLUGINS "")
function(add_triton_plugin name)
  set_property(GLOBAL APPEND PROPERTY TRITON_PLUGINS ${name})
  add_triton_object(${name} ${ARGN})
endfunction()


# Disable warnings that show up in external code (gtest;pybind11)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4244 /wd4624")

# Add include directories explicitly
include_directories(".")
if(MLIR_INCLUDE_DIRS)
  include_directories(${MLIR_INCLUDE_DIRS})
endif()
if(LLVM_INCLUDE_DIRS)
  include_directories(${LLVM_INCLUDE_DIRS})
endif()
include_directories(${PROJECT_SOURCE_DIR}/include)
include_directories(${PROJECT_BINARY_DIR}/include) # Tablegen'd files
include_directories(${PROJECT_SOURCE_DIR}/third_party)
include_directories(${PROJECT_BINARY_DIR}/third_party) # Tablegen'd files
# Add NVIDIA backend include paths conditionally
if(NOT TRITON_DISABLE_NVIDIA_BACKEND)
  include_directories(${PROJECT_SOURCE_DIR}/third_party/nvidia/include)
  include_directories(${PROJECT_BINARY_DIR}/third_party/nvidia/include)
endif()

# link_directories(${LLVM_LIBRARY_DIR})
add_subdirectory(include)
add_subdirectory(third_party/f2reduce)
add_subdirectory(lib)


# TODO: Figure out which target is sufficient to fix errors; triton is
# apparently not enough. Currently set linking libstdc++fs for all targets
# to support some old version GCC compilers like 8.3.0.

if(WIN32)
  add_subdirectory(third_party/dlfcn-win32)
  include_directories(${PROJECT_SOURCE_DIR}/third_party/dlfcn-win32)
endif()

# -----

# ------
if(TRITON_BUILD_PYTHON_MODULE)
  message(STATUS "Adding Python module")
  set(PYTHON_SRC_PATH ${CMAKE_CURRENT_SOURCE_DIR}/python/src)
  include_directories(${PYTHON_SRC_PATH})

  # Python Interpreter is used to run lit tests
  find_package(Python3 REQUIRED COMPONENTS Development.Module Interpreter)
  # Updated for pybind11 3.0.1 compatibility
  if(DEFINED PYBIND11_DIR)
    find_package(pybind11 REQUIRED PATHS ${PYBIND11_DIR} NO_DEFAULT_PATH)
  else()
    find_package(pybind11 REQUIRED)
  endif()

  # Add the python/src subdirectory to build the libtriton module
  add_subdirectory(python/src)

  if (DEFINED TRITON_PLUGIN_DIRS)
    foreach(PLUGIN_DIR ${TRITON_PLUGIN_DIRS})
      # Read the plugin name under dir/backend/name.conf
      cmake_path(APPEND PLUGIN_DIR "backend" "name.conf" OUTPUT_VARIABLE PLUGIN_NAME_PATH)
      file(READ ${PLUGIN_NAME_PATH} PLUGIN_NAME)
      string(STRIP ${PLUGIN_NAME} PLUGIN_NAME)

      list(APPEND TRITON_PLUGIN_NAMES ${PLUGIN_NAME})

      # Include the plugin as part of the build, placing the build output under
      # ${TRITON_BINARY_DIR}/third_party/${PLUGIN_NAME}
      cmake_path(APPEND TRITON_BINARY_DIR "third_party" ${PLUGIN_NAME} OUTPUT_VARIABLE PLUGIN_DIR_BUILD_OUTPUT)
      message(STATUS "Building plugin '${PLUGIN_NAME}' from ${PLUGIN_DIR} with output ${PLUGIN_DIR_BUILD_OUTPUT}")
      add_subdirectory(${PLUGIN_DIR} ${PLUGIN_DIR_BUILD_OUTPUT})
    endforeach()
  endif()

  # Only add NVIDIA backend if not disabled
  if(NOT TRITON_DISABLE_NVIDIA_BACKEND)
    foreach(CODEGEN_BACKEND ${TRITON_CODEGEN_BACKENDS})
      add_subdirectory(third_party/${CODEGEN_BACKEND})
    endforeach()
  endif()

  if (TRITON_BUILD_PROTON)
    add_subdirectory(third_party/proton)
  endif()
endif()