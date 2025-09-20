#ifndef TRITON_CONVERSION_TRITONNVIDIAGPU_TO_LLVM_PATTERNS_TRITON_GPU_OP_TO_LLVM_H
#define TRITON_CONVERSION_TRITONNVIDIAGPU_TO_LLVM_PATTERNS_TRITON_GPU_OP_TO_LLVM_H

#include "mlir/Conversion/LLVMCommon/TypeConverter.h"
#include "mlir/IR/PatternMatch.h"
#include "triton/Analysis/AxisInfo.h"

// Add missing includes for proper type resolution
#include "mlir/Conversion/LLVMCommon/Pattern.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/Location.h"
#include "mlir/IR/Builders.h"
// Replacing missing StringAttr.h with Attributes.h which contains StringAttr declaration
#include "mlir/IR/Attributes.h"
#include "mlir/Support/LogicalResult.h"
#include "mlir/Support/LLVM.h"

// Add missing includes for LLVM types
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Types.h"

// Include TargetInfoBase for proper type handling
#include "triton/Conversion/TritonGPUToLLVM/TargetInfoBase.h"

// Use full namespace qualification for types
namespace mlir {
namespace triton {

namespace NVIDIA {

void populateBarrierOpToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                                     ::mlir::RewritePatternSet &patterns,
                                     ::mlir::PatternBenefit benefit);

void populateClusterOpsToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                                      ::mlir::RewritePatternSet &patterns,
                                      ::mlir::PatternBenefit benefit);

void populateConvertLayoutOpToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                                           const ::mlir::triton::TargetInfoBase &targetInfo,
                                           ::mlir::RewritePatternSet &patterns,
                                           ::mlir::PatternBenefit benefit);

void populateMemoryOpToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                                    const ::mlir::triton::TargetInfoBase &targetInfo,
                                    ::mlir::RewritePatternSet &patterns,
                                    ::mlir::PatternBenefit benefit);

void populateConvertLayoutOpToLLVMOptimizedPatterns(
    ::mlir::LLVMTypeConverter &typeConverter, const ::mlir::triton::TargetInfoBase &targetInfo,
    ::mlir::RewritePatternSet &patterns, ::mlir::PatternBenefit benefit);

void populateDotOpToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                                 ::mlir::RewritePatternSet &patterns,
                                 ::mlir::PatternBenefit benefit);

void populateElementwiseOpToLLVMPatterns(
    ::mlir::LLVMTypeConverter &typeConverter, ::mlir::RewritePatternSet &patterns,
    ::mlir::triton::ModuleAxisInfoAnalysis &axisInfoAnalysis, int computeCapability,
    const ::mlir::triton::TargetInfoBase &targetInfo, ::mlir::PatternBenefit benefit);

void populateFp4ToFpToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                                   ::mlir::RewritePatternSet &patterns,
                                   ::mlir::PatternBenefit benefit);

void populateLoadStoreOpToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                                       const ::mlir::triton::TargetInfoBase &targetInfo,
                                       int computeCapability,
                                       ::mlir::RewritePatternSet &patterns,
                                       ::mlir::triton::ModuleAxisInfoAnalysis &axisInfoAnalysis,
                                       ::mlir::PatternBenefit benefit = 1);

void populateTensorPtrOpsToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                                        ::mlir::RewritePatternSet &patterns,
                                        ::mlir::PatternBenefit benefit);

void populateTMAToLLVMPatterns(::mlir::LLVMTypeConverter &typeConverter,
                               const ::mlir::triton::TargetInfoBase &targetInfo,
                               ::mlir::RewritePatternSet &patterns,
                               ::mlir::PatternBenefit benefit);

void populateSPMDOpToLLVMPattern(::mlir::LLVMTypeConverter &typeConverter,
                                 ::mlir::RewritePatternSet &patterns,
                                 ::mlir::PatternBenefit benefit);

void populateClampFOpToLLVMPattern(::mlir::LLVMTypeConverter &typeConverter,
                                   ::mlir::RewritePatternSet &patterns,
                                   ::mlir::triton::ModuleAxisInfoAnalysis &axisInfoAnalysis,
                                   int computeCapability,
                                   const ::mlir::triton::TargetInfoBase &targetInfo,
                                   ::mlir::PatternBenefit benefit);

void populateTCGen5MMAOpToLLVMPattern(::mlir::LLVMTypeConverter &typeConverter,
                                      ::mlir::RewritePatternSet &patterns,
                                      ::mlir::PatternBenefit benefit);

void populateTensorMemoryOpToLLVMPattern(::mlir::LLVMTypeConverter &typeConverter,
                                         ::mlir::RewritePatternSet &patterns,
                                         ::mlir::PatternBenefit benefit);

void populateTensorMemorySubviewOpToLLVMPattern(
    ::mlir::LLVMTypeConverter &typeConverter, ::mlir::RewritePatternSet &patterns,
    ::mlir::PatternBenefit benefit);
} // namespace NVIDIA
} // namespace triton
} // namespace mlir

#endif








