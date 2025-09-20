# Create the triton Python extension module
pybind11_add_module(libtriton
    ir.cc
    passes.cc
    llvm.cc
    interpreter.cc
    gluon_ir.cc
    main.cc
)

# Set C++ standard to C++17
set_target_properties(libtriton PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)

# Get the triton libraries
get_property(triton_libs GLOBAL PROPERTY TRITON_LIBS)
get_property(triton_plugins GLOBAL PROPERTY TRITON_PLUGINS)

# Check if NVIDIA backend is available and define macro accordingly
if(TARGET TritonNVIDIA)
    target_compile_definitions(libtriton PRIVATE TRITON_NVIDIA_BACKEND_AVAILABLE)
    message(STATUS "NVIDIA backend available - defining TRITON_NVIDIA_BACKEND_AVAILABLE")
else()
    message(STATUS "NVIDIA backend not available")
endif()

# Explicitly add the NVWS library directory for Windows builds
if(WIN32)
    # Add multiple possible paths where NVWSTransforms.lib might be built
    link_directories(${CMAKE_BINARY_DIR}/third_party/nvidia/lib/Dialect/NVWS/Transforms)
    link_directories(${CMAKE_CURRENT_BINARY_DIR}/third_party/nvidia/lib/Dialect/NVWS/Transforms)
    link_directories(${CMAKE_SOURCE_DIR}/build_vs/third_party/nvidia/lib/Dialect/NVWS/Transforms)
    link_directories(${CMAKE_SOURCE_DIR}/build/third_party/nvidia/lib/Dialect/NVWS/Transforms)
    
    # Try to find the NVWSTransforms library explicitly in multiple locations
    find_library(NVWS_LIB
        NAMES NVWSTransforms
        PATHS 
            ${CMAKE_BINARY_DIR}/third_party/nvidia/lib/Dialect/NVWS/Transforms
            ${CMAKE_CURRENT_BINARY_DIR}/third_party/nvidia/lib/Dialect/NVWS/Transforms
            ${CMAKE_SOURCE_DIR}/build_vs/third_party/nvidia/lib/Dialect/NVWS/Transforms
            ${CMAKE_SOURCE_DIR}/build/third_party/nvidia/lib/Dialect/NVWS/Transforms
        NO_DEFAULT_PATH
    )
    
    # If not found, try alternative paths with Release subdirectory
    if(NOT NVWS_LIB)
        find_library(NVWS_LIB
            NAMES NVWSTransforms
            PATHS
                ${CMAKE_BINARY_DIR}/third_party/nvidia/lib/Dialect/NVWS/Transforms/Release
                ${CMAKE_CURRENT_BINARY_DIR}/third_party/nvidia/lib/Dialect/NVWS/Transforms/Release
                ${CMAKE_SOURCE_DIR}/build_vs/third_party/nvidia/lib/Dialect/NVWS/Transforms/Release
                ${CMAKE_SOURCE_DIR}/build/third_party/nvidia/lib/Dialect/NVWS/Transforms/Release
            NO_DEFAULT_PATH
        )
    endif()
    
    # If still not found, set the direct paths for both possible build directories
    # Fix for double .lib extension issue - use just the library name instead of full path
    if(NOT NVWS_LIB)
        # Check if we're in the build_vs directory
        if(EXISTS "${CMAKE_SOURCE_DIR}/build_vs/third_party/nvidia/lib/Dialect/NVWS/Transforms/NVWSTransforms.lib")
            # Just use the library name to avoid double .lib extension
            set(NVWS_LIB "NVWSTransforms")
        elseif(EXISTS "${CMAKE_SOURCE_DIR}/build/third_party/nvidia/lib/Dialect/NVWS/Transforms/NVWSTransforms.lib")
            # Just use the library name to avoid double .lib extension
            set(NVWS_LIB "NVWSTransforms")
        else()
            # Fallback to the library name
            set(NVWS_LIB "NVWSTransforms")
        endif()
    endif()
    
    message(STATUS "Found NVWSTransforms library as: ${NVWS_LIB}")
endif()

# Link with triton libraries
target_link_libraries(libtriton PRIVATE 
    ${triton_libs}
    ${triton_plugins}
    Python3::Module 
    pybind11::headers
    
    # Explicitly link LLVM X86 target libraries for Windows to resolve LLVMInitializeX86* symbols
    LLVMX86AsmParser
    LLVMX86CodeGen
    LLVMX86Desc
    LLVMX86Info
    LLVMX86TargetMCA
    
    # Explicitly link NVWSTransforms to resolve NVWS pass symbols
    # Use the found library path if available, otherwise use the library name
    # Fix for double .lib extension issue - use target name directly when available
    $<$<TARGET_EXISTS:NVWSTransforms>:NVWSTransforms>
    $<$<AND:$<BOOL:${NVWS_LIB}>,$<NOT:$<TARGET_EXISTS:NVWSTransforms>>>:${NVWS_LIB}>
    $<$<AND:$<NOT:$<BOOL:${NVWS_LIB}>>,$<NOT:$<TARGET_EXISTS:NVWSTransforms>>>:NVWSTransforms>
)

# Conditionally link NVIDIA backend if available
# This is a key fix for the Windows build - proper linking with static library
if(TARGET TritonNVIDIA)
    message(STATUS "Linking with TritonNVIDIA static library")
    target_link_libraries(libtriton PRIVATE TritonNVIDIA)
endif()

# Include directories
target_include_directories(libtriton PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${PROJECT_SOURCE_DIR}/include
    ${PROJECT_BINARY_DIR}/include
)

# Set the output directory
set_target_properties(libtriton PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../../triton/_C
    ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../../triton/_C
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../../triton/_C
)

# Set the output name to libtriton
set_target_properties(libtriton PROPERTIES OUTPUT_NAME "libtriton")

# Add preprocessor definitions
target_compile_definitions(libtriton PRIVATE
    TRITON_BUILD_PYTHON_MODULE
    LLVM_NATIVE_ASMPARSER=LLVMInitializeX86AsmParser
    LLVM_NATIVE_ASMPRINTER=LLVMInitializeX86AsmPrinter
    LLVM_NATIVE_TARGET=LLVMInitializeX86Target
    LLVM_NATIVE_TARGETINFO=LLVMInitializeX86TargetInfo
    LLVM_NATIVE_TARGETMC=LLVMInitializeX86TargetMC
)