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
)

# Conditionally link NVIDIA backend if available
if(TARGET TritonNVIDIA)
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