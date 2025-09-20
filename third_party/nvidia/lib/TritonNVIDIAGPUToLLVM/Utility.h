#ifndef TRITON_CONVERSION_TRITONNVIDIAGPU_TO_LLVM_UTILITY_H
#define TRITON_CONVERSION_TRITONNVIDIAGPU_TO_LLVM_UTILITY_H

#include "TargetInfo.h"
#include "third_party/nvidia/include/TritonNVIDIAGPUToLLVM/PTXAsmFormat.h"

#include "triton/Conversion/TritonGPUToLLVM/Utility.h"

// Added missing MLIR headers for type definitions
#include "mlir/Conversion/LLVMCommon/Pattern.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Location.h"
#include "mlir/IR/Value.h"
#include "mlir/Support/LLVM.h"
#include "mlir/IR/Types.h"
#include <utility>
#include "third_party/nvidia/include/Dialect/NVGPU/IR/Dialect.h"
#include "triton/Analysis/Utility.h"
#include "triton/Conversion/MLIRTypes.h"
#include "triton/Dialect/TritonNvidiaGPU/IR/Dialect.h"

#define DEBUG_TYPE "ttgpu_to_llvm"

using namespace mlir;
using namespace mlir::triton;

// Shortcuts for some commonly used LLVM ops to keep code simple and intuitive
// Operators

namespace mlir {
namespace triton {
namespace NVIDIA {

Value getSRegValue(RewriterBase &rewriter, Location loc, StringRef sRegStr);
Value shuffleXor(Location loc, RewriterBase &rewriter, Value val, int i);
Value shuffleUp(Location loc, RewriterBase &rewriter, Value val, int i);
Value shuffleIdx(Location loc, RewriterBase &rewriter, Value val, int i);
Value shuffleIdx(Location loc, RewriterBase &rewriter, Value val, Value i);
Value permute(Location loc, RewriterBase &rewriter, Value a, Value b,
              Value mask);

Value llGetPid(Location loc, RewriterBase &rewriter, ModuleOp moduleOp,
               int axis);

/// Create a predicate with just single active thread.
Value createElectPredicate(Location loc, RewriterBase &rewriter);
Value createElectPredicateWarp0(Location loc, RewriterBase &rewriter);

// Create bar.warp.sync
void createSyncWarp(Location loc, OpBuilder &builder);

// Get lane and warp ID
std::pair<Value, Value> getLaneAndWarpId(RewriterBase &rewriter, Location loc);

// Get thread ID
Value getThreadId(RewriterBase &rewriter, Location loc);

// Check if index is canonical
bool isCanonicalIndex(size_t index, uint32_t mask);

// Utility function to perform logical AND if both operands are valid
inline Value maybeAnd(ConversionPatternRewriter &rewriter, Location loc, Value lhs, Value rhs) {
  if (!lhs) return rhs;
  if (!rhs) return lhs;
  auto b = TritonLLVMOpBuilder(loc, rewriter);
  return b.and_(lhs, rhs);
}

// Create L2 cache policy register
Value createCachePolicy(triton::EvictionPolicy opEvict,
                        ConversionPatternRewriter &rewriter, Location loc,
                        int computeCapability);

} // namespace NVIDIA
} // namespace triton

} // namespace mlir

#endif

