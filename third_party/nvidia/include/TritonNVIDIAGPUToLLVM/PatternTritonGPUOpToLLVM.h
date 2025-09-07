#ifndef TRITONNVIDIAGPU_CONVERSION_PATTERNTRITONGPUOPTOLLVM_H
#define TRITONNVIDIAGPU_CONVERSION_PATTERNTRITONGPUOPTOLLVM_H

#include "mlir/IR/PatternMatch.h"
#include "mlir/Conversion/LLVMCommon/TypeConverter.h"
#include "triton/Analysis/AxisInfo.h"
#include "third_party/nvidia/include/TritonNVIDIAGPUToLLVM/TargetInfo.h"
#include "triton/Conversion/TritonGPUToLLVM/TargetInfoBase.h"

namespace mlir {
namespace triton {
namespace NVIDIA {

void populateLoadStoreOpToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                                       const ::mlir::triton::TargetInfoBase &targetInfo,
                                       int computeCapability,
                                       ::mlir::RewritePatternSet &patterns,
                                       ::mlir::triton::ModuleAxisInfoAnalysis &axisInfoAnalysis,
                                       ::mlir::PatternBenefit benefit = 1);

} // namespace NVIDIA
} // namespace triton
} // namespace mlir

#endif // TRITONNVIDIAGPU_CONVERSION_PATTERNTRITONGPUOPTOLLVM_H