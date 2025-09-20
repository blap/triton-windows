#ifndef TRITONNVIDIAGPU_CONVERSION_PATTERNTRITONGPUOPTOLLVM_H
#define TRITONNVIDIAGPU_CONVERSION_PATTERNTRITONGPUOPTOLLVM_H

#include "mlir/Conversion/LLVMCommon/TypeConverter.h"
#include "mlir/IR/PatternMatch.h"  // Changed from mlir/IR/PatternSet.h
#include "triton/Analysis/AxisInfo.h"
#include "third_party/nvidia/include/TritonNVIDIAGPUToLLVM/TargetInfo.h"
#include "triton/Conversion/TritonGPUToLLVM/TargetInfoBase.h"

// Forward declarations to avoid include issues
namespace mlir {
  class LLVMTypeConverter;
  class RewritePatternSet;  // Changed from RewritePatternSet to match the actual class name
  class PatternBenefit;
  
  namespace triton {
    class ModuleAxisInfoAnalysis;
    class TargetInfoBase;
  }
}

namespace mlir {
namespace triton {
namespace NVIDIA {

void populateLoadStoreOpToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                                       const ::mlir::triton::TargetInfoBase &targetInfo,
                                       int computeCapability,
                                       ::mlir::RewritePatternSet &patterns,
                                       ::mlir::triton::ModuleAxisInfoAnalysis &axisInfoAnalysis,
                                       ::mlir::PatternBenefit benefit = 1);

void populateElementwiseOpToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                                         ::mlir::RewritePatternSet &patterns,
                                         ::mlir::triton::ModuleAxisInfoAnalysis &axisInfoAnalysis,
                                         int computeCapability,
                                         const ::mlir::triton::TargetInfoBase &targetInfo,
                                         ::mlir::PatternBenefit benefit);

void populateClampFOpToLLVMPattern(::mlir::LLVMTypeConverter &typeConverter,
                                   ::mlir::RewritePatternSet &patterns,
                                   ::mlir::triton::ModuleAxisInfoAnalysis &axisInfoAnalysis,
                                   int computeCapability,
                                   const ::mlir::triton::TargetInfoBase &targetInfo,
                                   ::mlir::PatternBenefit benefit);

} // namespace NVIDIA
} // namespace triton
} // namespace mlir

#endif // TRITONNVIDIAGPU_CONVERSION_PATTERNTRITONGPUOPTOLLVM_H