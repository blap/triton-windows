#include "third_party/nvidia/include/TritonNVIDIAGPUToLLVM/Utility.h"
#include "third_party/nvidia/include/TritonNVIDIAGPUToLLVM/PTXAsmFormat.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Location.h"
#include "mlir/IR/Builders.h"
#include "mlir/Conversion/LLVMCommon/Pattern.h"
#include "triton/Dialect/Triton/IR/Dialect.h"
#include "triton/Conversion/TritonGPUToLLVM/Utility.h"
#include "mlir/Dialect/LLVMIR/NVVMDialect.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/IR/TypeUtilities.h"
#include "llvm/ADT/Twine.h"

// Add missing LLVM and MLIR includes
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "mlir/IR/Types.h"
#include "mlir/IR/TypeRange.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/FunctionInterfaces.h"
#include "mlir/Transforms/DialectConversion.h"
#include "mlir/Dialect/LLVMIR/LLVMAttrs.h"

// Add namespace using declarations
using namespace mlir;
using namespace mlir::triton;

namespace mlir {
namespace triton {
namespace NVIDIA {

// Forward declaration
Value getSRegValue(RewriterBase &rewriter, Location loc, StringRef sRegStr);

static Value shuffleCommonImpl(Location loc, RewriterBase &rewriter, Value val,
                               Value i, NVVM::ShflKind mode, Value clamp) {
  auto b = TritonLLVMOpBuilder(loc, rewriter);
  unsigned bits = val.getType().getIntOrFloatBitWidth();

  if (bits == 64) {
    Type vecTy = vec_ty(f32_ty, 2);
    Value vec = b.bitcast(val, vecTy);
    Value val0 = b.extract_element(f32_ty, vec, b.i32_val(0));
    Value val1 = b.extract_element(f32_ty, vec, b.i32_val(1));
    val0 = shuffleCommonImpl(loc, rewriter, val0, i, mode, clamp);
    val1 = shuffleCommonImpl(loc, rewriter, val1, i, mode, clamp);
    vec = b.undef(vecTy);
    vec = b.insert_element(vecTy, vec, val0, b.i32_val(0));
    vec = b.insert_element(vecTy, vec, val1, b.i32_val(1));
    return b.bitcast(vec, val.getType());
  }
  Type type = val.getType();
  if (type != i32_ty) {
    val = b.bitcast(val, int_ty(bits));
    if (bits < 32)
      val = b.zext(i32_ty, val);
  }
  Value mask = b.i32_val(0xFFFFFFFF);
  Value result = rewriter.create<NVVM::ShflOp>(loc, i32_ty, mask, val, i, clamp,
                                               mode, UnitAttr());
  if (type != i32_ty) {
    if (bits < 32)
      result = b.trunc(int_ty(bits), result);
    result = b.bitcast(result, type);
  }
  return result;
}

static Value shuffleCommon(Location loc, RewriterBase &rewriter, Value val,
                           Value i, NVVM::ShflKind mode, Value clamp) {
  auto b = TritonLLVMOpBuilder(loc, rewriter);
  // To shuffle pointers, convert them to i64.
  Type valTy = val.getType();
  if (isa<LLVM::LLVMPointerType>(valTy))
    val = b.ptrtoint(i64_ty, val);
  Value result = shuffleCommonImpl(loc, rewriter, val, i, mode, clamp);
  if (isa<LLVM::LLVMPointerType>(valTy))
    result = b.inttoptr(valTy, result);
  return result;
}

Value shuffleXor(Location loc, RewriterBase &rewriter, Value val, int i) {
  auto b = TritonLLVMOpBuilder(loc, rewriter);
  return shuffleCommon(loc, rewriter, val, b.i32_val(i), NVVM::ShflKind::bfly,
                       b.i32_val(0x1f));
}

Value shuffleUp(Location loc, RewriterBase &rewriter, Value val, int i) {
  auto b = TritonLLVMOpBuilder(loc, rewriter);
  return shuffleCommon(loc, rewriter, val, b.i32_val(i), NVVM::ShflKind::up,
                       b.i32_val(0x0));
}

Value shuffleIdx(Location loc, RewriterBase &rewriter, Value val, int i) {
  auto b = TritonLLVMOpBuilder(loc, rewriter);
  return shuffleCommon(loc, rewriter, val, b.i32_val(i), NVVM::ShflKind::idx,
                       b.i32_val(0x1f));
}

Value shuffleIdx(Location loc, RewriterBase &rewriter, Value val, Value i) {
  auto b = TritonLLVMOpBuilder(loc, rewriter);
  return shuffleCommon(loc, rewriter, val, i, NVVM::ShflKind::idx,
                       b.i32_val(0x1f));
}

Value llGetPid(Location loc, RewriterBase &rewriter, ModuleOp moduleOp,
               int axis) {
  assert(axis >= 0);
  assert(axis < 3);
  assert(moduleOp);

  // It is not easy to get the compute capability here, so we use numCTAs to
  // decide the semantic of GetProgramIdOp. If numCTAs = 1, then
  // GetProgramIdOp is converted to "%ctaid", otherwise it is converted to
  // "%clusterid".
  int numCTAs = triton::gpu::TritonGPUDialect::getNumCTAs(moduleOp);

  std::string sreg = numCTAs == 1 ? "ctaid." : "clusterid.";
  sreg.append(1, 'x' + axis); // 0 -> 'x', 1 -> 'y', 2 -> 'z'
  return getSRegValue(rewriter, loc, sreg);
}

Value getSRegValue(RewriterBase &rewriter, Location loc, StringRef sRegStr) {
  ValueRange args;
  auto intrName = Twine("llvm.nvvm.read.ptx.sreg.") + sRegStr;
  auto callOp =
      LLVM::createLLVMIntrinsicCallOp(rewriter, loc, intrName.str(), i32_ty, args);
  return callOp.getResult(0);
}

Value getThreadId(RewriterBase &rewriter, Location loc) {
  return getSRegValue(rewriter, loc, "tid.x");
}

// Placeholder implementation for isCanonicalIndex
bool isCanonicalIndex(size_t index, uint32_t mask) {
  return (index & ~static_cast<size_t>(mask)) == index;
}

Value permute(Location loc, RewriterBase &rewriter, Value a, Value b,
              Value mask) {
  Value args[] = {a, b, mask};
  auto op =
      LLVM::createLLVMIntrinsicCallOp(rewriter, loc, "llvm.nvvm.prmt", i32_ty, args);
  return op.getResult(0);
}

/// Create a predicate with just single active thread.
Value createElectPredicate(Location loc, RewriterBase &rewriter) {
  return rewriter.create<NVVM::ElectSyncOp>(loc, i1_ty);
}

void createSyncWarp(Location loc, OpBuilder &rewriter) {
  TritonLLVMOpBuilder b(loc, rewriter);
  Type resultTy = void_ty(rewriter.getContext());
  Value args[] = {b.i32_val(0xffffffff)};
  LLVM::createLLVMIntrinsicCallOp(rewriter, loc, "llvm.nvvm.bar.warp.sync", resultTy,
                            args);
}

Value createElectPredicateWarp0(Location loc, RewriterBase &rewriter) {
  auto b = TritonLLVMOpBuilder(loc, rewriter);
  Value threadId = getThreadId(rewriter, loc);
  Value warp0 = b.icmp_ult(threadId, b.i32_val(32));
  return b.and_(warp0, createElectPredicate(loc, rewriter));
}

std::pair<Value, Value> getLaneAndWarpId(RewriterBase &rewriter, Location loc) {
  auto b = TritonLLVMOpBuilder(loc, rewriter);
  Value threadId = getThreadId(rewriter, loc);
  Value laneId = b.urem(threadId, b.i32_val(32));
  Value warpId = b.udiv(threadId, b.i32_val(32));
  return std::make_pair(laneId, warpId);
}

Value createCachePolicy(triton::EvictionPolicy opEvict,
                        ConversionPatternRewriter &rewriter, Location loc,
                        int computeCapability) {
  // Emit createpolicy.fractional.L2::policy.b64 xx 1.0
  triton::PTXBuilder ptxBuilder;
  const bool hasL2EvictPolicy =
      opEvict == triton::EvictionPolicy::EVICT_FIRST ||
      opEvict == triton::EvictionPolicy::EVICT_LAST;
  Value policyRet;

  const bool hardwareSupport = computeCapability >= 80;

  if (hasL2EvictPolicy && hardwareSupport) {
    auto &policy =
        ptxBuilder.create<>("createpolicy.fractional")
            ->o("L2::evict_first",
                opEvict == triton::EvictionPolicy::EVICT_FIRST)
            .o("L2::evict_last", opEvict == triton::EvictionPolicy::EVICT_LAST)
            .b(64);

    const std::string writeConstraint = "=l";
    // prepare asm operands
    auto *dstOpr = ptxBuilder.newOperand(writeConstraint, /*init=*/true);
    std::string fractionStr = "1.0";
    auto *fractionOpr = ptxBuilder.newConstantOperand(fractionStr);
    policy(dstOpr, fractionOpr);

    Type policyRetTy = rewriter.getI64Type();
    policyRet = ptxBuilder.launch(rewriter, loc, policyRetTy);
  }

  return policyRet;
}

} // namespace NVIDIA
} // namespace triton
} // namespace mlir