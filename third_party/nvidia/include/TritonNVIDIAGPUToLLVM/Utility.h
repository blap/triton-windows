#ifndef TRITONGPU_CONVERSION_TRITONNVIDIAGPUTOLLVM_UTILITY_H
#define TRITONGPU_CONVERSION_TRITONNVIDIAGPUToLLVM_UTILITY_H

#include "mlir/IR/Operation.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Location.h"
#include "mlir/IR/Builders.h"
#include "mlir/Conversion/LLVMCommon/Pattern.h"  // Add this include for ConversionPatternRewriter
#include "mlir/Conversion/LLVMCommon/TypeConverter.h"
#include "mlir/Transforms/DialectConversion.h"
#include "triton/Dialect/Triton/IR/Dialect.h"
#include "triton/Analysis/AxisInfo.h"
#include "triton/Conversion/TritonGPUToLLVM/TargetInfoBase.h"

namespace mlir {
namespace triton {
namespace NVIDIA {

/// Return true if we can skip a barrier synchronization between two operations
/// even if they access the same shared memory.
bool canSkipBarSync(Operation *before, Operation *after);

/// Create a sync warp operation
void createSyncWarp(Location loc, OpBuilder &builder);

// Additional NVIDIA utility function declarations
Value shuffleXor(Location loc, RewriterBase &rewriter, Value val, int i);
Value shuffleUp(Location loc, RewriterBase &rewriter, Value val, int i);
Value shuffleIdx(Location loc, RewriterBase &rewriter, Value val, int i);
Value shuffleIdx(Location loc, RewriterBase &rewriter, Value val, Value i);
Value getThreadId(RewriterBase &rewriter, Location loc);
std::pair<Value, Value> getLaneAndWarpId(RewriterBase &rewriter, Location loc);
bool isCanonicalIndex(size_t index, uint32_t mask);
Value createElectPredicateWarp0(Location loc, RewriterBase &rewriter);
Value createCachePolicy(triton::EvictionPolicy opEvict,
                        ConversionPatternRewriter &rewriter, Location loc,
                        int computeCapability);

} // namespace NVIDIA
} // namespace triton
} // namespace mlir

#endif // TRITONGPU_CONVERSION_TRITONNVIDIAGPUTOLLVM_UTILITY_H