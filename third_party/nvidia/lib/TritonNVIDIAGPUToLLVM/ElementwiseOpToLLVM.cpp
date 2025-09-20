#include "mlir/Conversion/LLVMCommon/Pattern.h"
#include "mlir/Conversion/LLVMCommon/TypeConverter.h"
#include "mlir/Dialect/GPU/IR/GPUDialect.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/LLVMIR/LLVMTypes.h"
#include "mlir/Dialect/LLVMIR/NVVMDialect.h"
#include "mlir/Dialect/Math/IR/Math.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/TypeUtilities.h"
#include "mlir/Support/LLVM.h"
#include "triton/Conversion/TritonGPUToLLVM/ElementwiseOpToLLVMBase.h"
#include "triton/Conversion/TritonGPUToLLVM/PatternTritonGPUOpToLLVM.h"
#include "triton/Conversion/TritonGPUToLLVM/TargetInfoBase.h"
#include "triton/Conversion/TritonGPUToLLVM/Utility.h"
#include "triton/Dialect/Triton/IR/Dialect.h"
#include "triton/Dialect/Triton/IR/Types.h"
#include "triton/Dialect/TritonGPU/IR/Dialect.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Debug.h"
#include <array>

// Fixed path to reference the correct location of PTXAsmFormat.h
#include "third_party/nvidia/include/TritonNVIDIAGPUToLLVM/PTXAsmFormat.h"

using namespace mlir;
using namespace mlir::triton;

namespace {

// Trivial case where we map elementwise to an existing LLVM operator
template <typename SourceOp, typename DestOp>
struct ElementwiseOpConversion
    : public mlir::triton::gpu::ElementwiseOpConversionBase<
          SourceOp, ElementwiseOpConversion<SourceOp, DestOp>> {
  using Base =
      mlir::triton::gpu::ElementwiseOpConversionBase<SourceOp,
                                  ElementwiseOpConversion<SourceOp, DestOp>>;
  using Base::Base;
  using OpAdaptor = typename Base::OpAdaptor;

  // An interface to support variant DestOp builder.
  SmallVector<DestOp> createDestOps(SourceOp op, OpAdaptor adaptor,
                                    ConversionPatternRewriter &rewriter,
                                    Type elemTy, mlir::triton::gpu::MultipleOperandsRange operands,
                                    Location loc) const {
    return {rewriter.create<DestOp>(loc, elemTy, operands[0],
                                    adaptor.getAttributes().getValue())};
  }
};

// OpToExternCallConversion maps a SourceOp to an external function call.
// The external function name is given as a template argument.
template <typename SourceOp>
struct OpToExternCallConversion
    : public mlir::triton::gpu::ElementwiseOpConversionBase<
          SourceOp, OpToExternCallConversion<SourceOp>> {
  using Base =
      mlir::triton::gpu::ElementwiseOpConversionBase<SourceOp,
                                  OpToExternCallConversion<SourceOp>>;
  using Base::Base;
  using OpAdaptor = typename Base::OpAdaptor;

  explicit OpToExternCallConversion(LLVMTypeConverter &typeConverter,
                                    ModuleAxisInfoAnalysis &axisAnalysisPass,
                                    const char *funcName,
                                    PatternBenefit benefit = 1)
      : Base::ElementwiseOpConversionBase(typeConverter, axisAnalysisPass, benefit),
        funcName(funcName) {}

  SmallVector<Value> createDestOps(SourceOp op, OpAdaptor adaptor,
                                   ConversionPatternRewriter &rewriter,
                                   Type elemTy, mlir::triton::gpu::MultipleOperandsRange operands,
                                   Location loc) const {
    Type funcType = mlir::triton::gpu::getFunctionType(elemTy, operands[0]);
    LLVM::LLVMFuncOp funcOp =
        mlir::triton::gpu::appendOrGetExternFuncOp(rewriter, op, funcName, funcType);
    return {
        rewriter.create<LLVM::CallOp>(loc, funcOp, operands[0]).getResult()};
  }

private:
  const char *funcName;
};

// Conversion for FDivOp
struct FDivOpConversion
    : public mlir::triton::gpu::ElementwiseOpConversionBase<
          arith::DivFOp, FDivOpConversion> {
  using Base =
      mlir::triton::gpu::ElementwiseOpConversionBase<arith::DivFOp,
                                                     FDivOpConversion>;
  using Base::Base;
  using OpAdaptor = typename Base::OpAdaptor;

  SmallVector<Value> createDestOps(arith::DivFOp op, OpAdaptor adaptor,
                                   ConversionPatternRewriter &rewriter,
                                   Type elemTy, mlir::triton::gpu::MultipleOperandsRange operands,
                                   Location loc) const {
    auto b = TritonLLVMOpBuilder(loc, rewriter);
    PTXBuilder ptxBuilder;
    auto &fdiv = *ptxBuilder.create("div.rn.f32");
    auto res = ptxBuilder.newOperand("=r");
    auto lhs = ptxBuilder.newOperand(operands[0][0], "r");
    auto rhs = ptxBuilder.newOperand(operands[0][1], "r");
    fdiv(res, lhs, rhs);
    return {ptxBuilder.launch(rewriter, loc, elemTy, false)};
  }
};

// Conversion for FPToSIOp
struct FPToSIOpConversion
    : public mlir::triton::gpu::ElementwiseOpConversionBase<
          arith::FPToSIOp, FPToSIOpConversion> {
  using Base =
      mlir::triton::gpu::ElementwiseOpConversionBase<arith::FPToSIOp,
                                                     FPToSIOpConversion>;
  using Base::Base;
  using OpAdaptor = typename Base::OpAdaptor;

  SmallVector<Value> createDestOps(arith::FPToSIOp op, OpAdaptor adaptor,
                                   ConversionPatternRewriter &rewriter,
                                   Type elemTy, mlir::triton::gpu::MultipleOperandsRange operands,
                                   Location loc) const {
    auto b = TritonLLVMOpBuilder(loc, rewriter);
    PTXBuilder ptxBuilder;
    auto &cvt = *ptxBuilder.create("cvt.rni.s32.f32");
    auto res = ptxBuilder.newOperand("=r");
    auto val = ptxBuilder.newOperand(operands[0][0], "r");
    cvt(res, val);
    return {ptxBuilder.launch(rewriter, loc, elemTy, false)};
  }
};

// Conversion for SIToFPOp
struct SIToFPOpConversion
    : public mlir::triton::gpu::ElementwiseOpConversionBase<
          arith::SIToFPOp, SIToFPOpConversion> {
  using Base =
      mlir::triton::gpu::ElementwiseOpConversionBase<arith::SIToFPOp,
                                                     SIToFPOpConversion>;
  using Base::Base;
  using OpAdaptor = typename Base::OpAdaptor;

  explicit SIToFPOpConversion(LLVMTypeConverter &typeConverter,
                              ModuleAxisInfoAnalysis &axisAnalysisPass,
                              int computeCapability,
                              PatternBenefit benefit = 1)
      : Base::ElementwiseOpConversionBase(typeConverter, axisAnalysisPass, benefit),
        computeCapability(computeCapability) {}

  SmallVector<Value> createDestOps(arith::SIToFPOp op, OpAdaptor adaptor,
                                   ConversionPatternRewriter &rewriter,
                                   Type elemTy, mlir::triton::gpu::MultipleOperandsRange operands,
                                   Location loc) const {
    auto b = TritonLLVMOpBuilder(loc, rewriter);
    PTXBuilder ptxBuilder;
    std::string inst =
        computeCapability >= 90 ? "cvt.rn.f32.s32" : "cvt.rn.f32.s32";
    auto &cvt = *ptxBuilder.create(inst);
    auto res = ptxBuilder.newOperand("=r");
    auto val = ptxBuilder.newOperand(operands[0][0], "r");
    cvt(res, val);
    return {ptxBuilder.launch(rewriter, loc, elemTy, false)};
  }

private:
  int computeCapability;
};

// Conversion for FpToFpOp
struct FpToFpOpConversion
    : public mlir::triton::gpu::ElementwiseOpConversionBase<
          triton::FpToFpOp, FpToFpOpConversion> {
  using Base =
      mlir::triton::gpu::ElementwiseOpConversionBase<triton::FpToFpOp,
                                                     FpToFpOpConversion>;
  using Base::Base;
  using OpAdaptor = typename Base::OpAdaptor;

  explicit FpToFpOpConversion(LLVMTypeConverter &typeConverter,
                              ModuleAxisInfoAnalysis &axisAnalysisPass,
                              int computeCapability,
                              PatternBenefit benefit = 1)
      : Base::ElementwiseOpConversionBase(typeConverter, axisAnalysisPass, benefit),
        computeCapability(computeCapability) {}

  SmallVector<Value> createDestOps(triton::FpToFpOp op, OpAdaptor adaptor,
                                   ConversionPatternRewriter &rewriter,
                                   Type elemTy, mlir::triton::gpu::MultipleOperandsRange operands,
                                   Location loc) const {
    auto b = TritonLLVMOpBuilder(loc, rewriter);
    auto srcElementType = getElementTypeOrSelf(op.getSrc());
    auto dstElementType = elemTy;

    // Handle FP8 conversions with inline PTX
    if (llvm::isa<mlir::Float8E5M2Type>(dstElementType) || llvm::isa<mlir::Float8E4M3FNType>(dstElementType) ||
        llvm::isa<mlir::Float8E5M2Type>(srcElementType) || llvm::isa<mlir::Float8E4M3FNType>(srcElementType)) {
      PTXBuilder ptxBuilder;
      std::string inst = getConvertInst(srcElementType, dstElementType);
      auto &cvt = *ptxBuilder.create(inst);
      auto res = ptxBuilder.newOperand("=h");
      auto val = ptxBuilder.newOperand(operands[0][0], "h");
      cvt(res, val);
      return {ptxBuilder.launch(rewriter, loc, elemTy, false)};
    }

    // For other conversions, use standard LLVM operations
    return {rewriter.create<LLVM::FPExtOp>(loc, elemTy, operands[0][0])};
  }

private:
  std::string getConvertInst(Type srcType, Type dstType) const {
    if (srcType.isF32() && llvm::isa<mlir::Float8E5M2Type>(dstType)) {
      return "cvt.rn.f16.f32";
    } else if (srcType.isF32() && llvm::isa<mlir::Float8E4M3FNType>(dstType)) {
      return "cvt.rn.f16.f32";
    } else if (llvm::isa<mlir::Float8E5M2Type>(srcType) && dstType.isF32()) {
      return "cvt.f32.f16";
    } else if (llvm::isa<mlir::Float8E4M3FNType>(srcType) && dstType.isF32()) {
      return "cvt.f32.f16";
    } else if (srcType.isF16() && llvm::isa<mlir::Float8E5M2Type>(dstType)) {
      return "cvt.rn.f16.f16";
    } else if (srcType.isF16() && llvm::isa<mlir::Float8E4M3FNType>(dstType)) {
      return "cvt.rn.f16.f16";
    } else if (llvm::isa<mlir::Float8E5M2Type>(srcType) && srcType.isF16()) {
      return "cvt.f16.f16";
    } else if (llvm::isa<mlir::Float8E4M3FNType>(srcType) && srcType.isF16()) {
      return "cvt.f16.f16";
    }
    return "cvt.rn.f16.f32"; // fallback
  }

  int computeCapability;
};

// Conversion for ExpOp with approximation
struct ExpOpConversionApprox
    : public mlir::triton::gpu::ElementwiseOpConversionBase<
          math::ExpOp, ExpOpConversionApprox> {
  using Base =
      mlir::triton::gpu::ElementwiseOpConversionBase<math::ExpOp,
                                                     ExpOpConversionApprox>;
  using Base::Base;
  using OpAdaptor = typename Base::OpAdaptor;

  explicit ExpOpConversionApprox(LLVMTypeConverter &typeConverter,
                                 ModuleAxisInfoAnalysis &axisAnalysisPass,
                                 PatternBenefit benefit = 1)
      : Base::ElementwiseOpConversionBase(typeConverter, axisAnalysisPass, benefit) {}

  SmallVector<Value> createDestOps(math::ExpOp op, OpAdaptor adaptor,
                                   ConversionPatternRewriter &rewriter,
                                   Type elemTy, mlir::triton::gpu::MultipleOperandsRange operands,
                                   Location loc) const {
    auto b = TritonLLVMOpBuilder(loc, rewriter);
    PTXBuilder ptxBuilder;
    auto &exp2 = *ptxBuilder.create("ex2.approx.f32");
    auto res = ptxBuilder.newOperand("=r");
    auto val = ptxBuilder.newOperand(operands[0][0], "r");
    
    // Convert from e^x to 2^(x * log2(e))
    auto log2e = b.f32_val(1.4426950408889634f);
    auto scaled = b.fmul(operands[0][0], log2e);
    
    auto val_scaled = ptxBuilder.newOperand(scaled, "r");
    exp2(res, val_scaled);
    return {ptxBuilder.launch(rewriter, loc, elemTy, false)};
  }
};

} // anonymous namespace

namespace mlir {
namespace triton {
namespace NVIDIA {

void populateElementwiseOpToLLVMPatterns(
    LLVMTypeConverter &typeConverter, RewritePatternSet &patterns,
    ModuleAxisInfoAnalysis &axisInfoAnalysis, int computeCapability,
    const ::mlir::triton::TargetInfoBase &targetInfo, PatternBenefit benefit) {
  using namespace mlir::triton::gpu;

  // Call the base implementation first
  ::mlir::triton::populateElementwiseOpToLLVMPatterns(
      typeConverter, patterns, axisInfoAnalysis, targetInfo, benefit);

  // Add NVIDIA-specific patterns
  patterns.add<OpToExternCallConversion<triton::PreciseSqrtOp>>(
      typeConverter, axisInfoAnalysis, "__nv_fsqrt_rn", benefit);
  patterns.add<OpToExternCallConversion<triton::PreciseDivFOp>>(
      typeConverter, axisInfoAnalysis, "__nv_fdiv_rn", benefit);

#define POPULATE_OP(SRC_OP, DST_OP)                                            \
  patterns.add<ElementwiseOpConversion<SRC_OP, DST_OP>>(                       \
      typeConverter, axisInfoAnalysis, benefit)

  POPULATE_OP(arith::SubFOp, LLVM::FSubOp);
  POPULATE_OP(arith::AddFOp, LLVM::FAddOp);
  POPULATE_OP(arith::MulFOp, LLVM::FMulOp);

  POPULATE_OP(arith::ExtFOp, LLVM::FPExtOp);
  POPULATE_OP(arith::TruncFOp, LLVM::FPTruncOp);

#undef POPULATE_OP

  patterns.add<FDivOpConversion>(typeConverter, axisInfoAnalysis, benefit);
  patterns.add<FPToSIOpConversion>(typeConverter, axisInfoAnalysis, benefit);
  patterns.add<SIToFPOpConversion>(typeConverter, axisInfoAnalysis,
                                   computeCapability, benefit);
  patterns.add<FpToFpOpConversion>(typeConverter, axisInfoAnalysis,
                                   computeCapability, benefit);

  // ExpOpConversionApprox will try using ex2.approx if the input type is
  // FP32. For other input types, ExpOpConversionApprox will return failure and
  // ElementwiseOpConversion<math::ExpOp, math::ExpOp> defined below will call
  // __nv_expf for higher-precision calculation
  patterns.add<ExpOpConversionApprox>(typeConverter, axisInfoAnalysis, benefit);
  
  bool hwNanPropagationSupported = computeCapability >= 80;
  ::mlir::triton::populateMinMaxFOpToLLVMPattern(
      typeConverter, patterns, axisInfoAnalysis, hwNanPropagationSupported,
      benefit);
}

void populateClampFOpToLLVMPattern(
    LLVMTypeConverter &typeConverter, RewritePatternSet &patterns,
    ModuleAxisInfoAnalysis &axisInfoAnalysis, int computeCapability,
    const ::mlir::triton::TargetInfoBase &targetInfo, PatternBenefit benefit) {
  // Call the base implementation
  ::mlir::triton::populateClampFOpToLLVMPattern(
      typeConverter, patterns, axisInfoAnalysis, targetInfo, benefit);
}

} // namespace NVIDIA
} // namespace triton
} // namespace mlir