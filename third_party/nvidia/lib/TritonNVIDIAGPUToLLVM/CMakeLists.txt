add_triton_library(TritonNVIDIAGPUToLLVM
    ConvertLayoutOpToLLVM.cpp
    ConvertWarpSpecializeToLLVM.cpp
    MemoryOpToLLVM.cpp
    DotOpToLLVM/MMAv2.cpp
    DotOpToLLVM/MMAv5.cpp
    DotOpToLLVM/WGMMA.cpp
    DotOpToLLVM.cpp
    ElementwiseOpToLLVM.cpp
    LoadStoreOpToLLVM.cpp  # Uncommented problematic file
    BarrierOpToLLVM.cpp
    TritonGPUToLLVM.cpp
    TMAToLLVM.cpp  # Uncommented TMA-related file
    SPMDOpToLLVM.cpp
    TensorMemoryToLLVM.cpp
    TensorPtrOpsToLLVM.cpp
    ClusterOpsToLLVM.cpp
    PTXAsmFormat.cpp
    Utility.cpp
    TargetInfo.cpp
    Fp4ToFpOpToLLVM.cpp

    DEPENDS
    TritonNVIDIAGPUConversionPassIncGen
    NVGPUAttrDefsIncGen
    NVGPUTableGen

    LINK_LIBS PUBLIC
    TritonGPUToLLVM
    MLIRReconcileUnrealizedCasts
    MLIRMathToLLVM
)

if (TRITON_BUILD_PROTON)
    target_link_libraries(TritonNVIDIAGPUToLLVM PUBLIC TritonProtonToLLVM)
endif()