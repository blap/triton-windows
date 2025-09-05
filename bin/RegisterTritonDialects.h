#pragma once
#include "triton/Dialect/Triton/IR/Dialect.h"
#include "triton/Dialect/TritonGPU/IR/Dialect.h"
#include "triton/Dialect/TritonNvidiaGPU/IR/Dialect.h"
// Fixed paths to reference build directory for generated files - Windows build compatibility
#include "third_party/nvidia/include/Dialect/NVGPU/IR/Dialect.h"
#include "third_party/nvidia/include/Dialect/NVWS/IR/Dialect.h"

// Conditional compilation for Proton profiler - Windows build enhancement
#ifdef TRITON_BUILD_PROTON
#include "third_party/proton/dialect/include/Dialect/Proton/IR/Dialect.h"
#endif


#include "triton/Dialect/Triton/Transforms/Passes.h"
// Fixed typo in include path - Windows build fix
#include "triton/Dialect/TritonGPU/Transforms/Passes.h"
#include "triton/Dialect/TritonNvidiaGPU/Transforms/Passes.h"

#include "third_party/nvidia/hopper/include/Transforms/Passes.h"
#include "third_party/nvidia/include/Dialect/NVWS/Transforms/Passes.h"
#include "third_party/nvidia/include/NVGPUToLLVM/Passes.h"
#include "third_party/nvidia/include/TritonNVIDIAGPUToLLVM/Passes.h"
#include "triton/Conversion/TritonGPUToLLVM/Passes.h"
#include "triton/Conversion/TritonToTritonGPU/Passes.h"
#include "triton/Target/LLVMIR/Passes.h"

#include "mlir/Dialect/LLVMIR/NVVMDialect.h"
#include "mlir/InitAllPasses.h"
// Added for Triton dialect translation registration - Windows build enhancement
#include "mlir/Target/LLVMIR/Dialect/LLVMIR/LLVMToLLVMIRTranslation.h"

namespace mlir {
namespace test {
void registerTestAliasPass();
void registerTestAlignmentPass();
void registerTestAllocationPass();
void registerTestMembarPass();
void registerTestLoopPeelingPass();
} // namespace test
} // namespace mlir

// Register all Triton dialects and passes - Windows build enhancement
inline void registerTritonDialects(mlir::DialectRegistry &registry) {
  mlir::registerAllPasses();
  mlir::triton::registerTritonPasses();
  mlir::triton::gpu::registerTritonGPUPasses();
  mlir::triton::nvidia_gpu::registerTritonNvidiaGPUPasses();
  mlir::test::registerTestAliasPass();
  mlir::test::registerTestAlignmentPass();
  mlir::test::registerTestAllocationPass();
  mlir::test::registerTestMembarPass();
  mlir::test::registerTestLoopPeelingPass();
  mlir::triton::registerConvertTritonToTritonGPUPass();
  mlir::triton::registerRelayoutTritonGPUPass();
  mlir::triton::gpu::registerAllocateSharedMemoryPass();
  mlir::triton::gpu::registerTritonGPUAllocateWarpGroups();
  mlir::triton::gpu::registerTritonGPUGlobalScratchAllocationPass();
  mlir::triton::registerConvertWarpSpecializeToLLVM();
  mlir::triton::registerConvertTritonGPUToLLVMPass();
  mlir::triton::registerConvertNVGPUToLLVMPass();
  mlir::registerLLVMDIScope();

  // NVWS passes - Windows NVIDIA backend support
  mlir::triton::registerNVWSTransformsPasses();

  // NVGPU transform passes - Windows NVIDIA backend support
  mlir::registerNVHopperTransformsPasses();

  registry.insert<
      mlir::triton::TritonDialect, mlir::cf::ControlFlowDialect,
      mlir::triton::nvidia_gpu::TritonNvidiaGPUDialect,
      mlir::triton::gpu::TritonGPUDialect, mlir::math::MathDialect,
      mlir::arith::ArithDialect, mlir::scf::SCFDialect, mlir::gpu::GPUDialect,
      mlir::LLVM::LLVMDialect, mlir::NVVM::NVVMDialect,
      mlir::triton::nvgpu::NVGPUDialect, mlir::triton::nvws::NVWSDialect
// Conditional compilation for Proton dialect - Windows build enhancement
#ifdef TRITON_BUILD_PROTON
      , mlir::triton::proton::ProtonDialect
#endif
      >();
      
  // Register LLVM translation interface for Triton dialect - Windows build enhancement
  mlir::registerLLVMDialectTranslation(registry);
}