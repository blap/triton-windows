#ifndef TRITON_CONVERSION_TRITONGPU_TO_LLVM_TARGETINFONVIDIA_H
#define TRITON_CONVERSION_TRITONGPU_TO_LLVM_TARGETINFONVIDIA_H

// Fixed path to reference the correct location of TargetInfoBase.h
#include "triton/Conversion/TritonGPUToLLVM/TargetInfoBase.h"

namespace mlir::triton::NVIDIA {

class TargetInfo : public mlir::triton::TargetInfoBase {
public:
  TargetInfo(int computeCapability, int ptxVersion)
      : computeCapability(computeCapability), ptxVersion(ptxVersion) {}

  bool supportMaximumMinimum() const override;

  mlir::Value getClusterCTAId(mlir::RewriterBase &rewriter, mlir::Location loc) const override;

  mlir::Value ballot(mlir::RewriterBase &rewriter, mlir::Location loc, mlir::Type type,
               mlir::Value cmp) const override;

  void storeDShared(mlir::RewriterBase &rewriter, mlir::Location loc, mlir::Value ptr,
                    std::optional<mlir::Value> ctaId, mlir::Value val,
                    mlir::Value pred) const override;
  mlir::Value loadDShared(mlir::RewriterBase &rewriter, mlir::Location loc, mlir::Value ptr,
                    std::optional<mlir::Value> ctaId, mlir::Type elemTy,
                    mlir::Value pred) const override;

  // FIXME: Need to kill this function
  bool canUseStMatrix(mlir::RankedTensorType tensorTy, llvm::ArrayRef<unsigned> repShape,
                      llvm::ArrayRef<unsigned> paddedRepShape,
                      llvm::ArrayRef<unsigned> order,
                      int swizzleByteSize) const override;

  bool supportLdMatrix() const override { return computeCapability >= 75; }
  bool supportStMatrix() const override { return computeCapability >= 90; }

  void storeMatrixShared(mlir::RewriterBase &rewriter, mlir::Location loc, mlir::Value ptr,
                         mlir::Value val) const override;

  mlir::Value shuffleXor(mlir::RewriterBase &rewriter, mlir::Location loc, mlir::Value val,
                   int i) const override;
  mlir::Value shuffleUp(mlir::RewriterBase &rewriter, mlir::Location loc, mlir::Value val,
                  int i) const override;
  mlir::Value shuffleIdx(mlir::RewriterBase &rewriter, mlir::Location loc, mlir::Value val,
                   int i) const override;
  mlir::Value shuffleIdx(mlir::RewriterBase &rewriter, mlir::Location loc, mlir::Value val,
                   mlir::Value i) const override;

  mlir::Value programId(mlir::RewriterBase &rewriter, mlir::Location loc, mlir::ModuleOp moduleOp,
                  int axis) const override;

  bool warpReduce(mlir::RewriterBase &rewriter, mlir::Location loc, llvm::SmallVector<mlir::Value> &acc,
                  triton::ReduceOp op, unsigned numLaneToReduce,
                  unsigned interleave) const override;

  std::string getMulhiFuncName(mlir::Type resultElementTy) const override;

  void printf(mlir::RewriterBase &rewriter, mlir::Value formatStrStart,
              int formatStrByteCount, mlir::ValueRange args,
              llvm::ArrayRef<bool> isSigned = {}) const override;

  void printf(mlir::RewriterBase &rewriter, llvm::StringRef msg, mlir::ValueRange args,

              llvm::ArrayRef<bool> isSigned = {}) const override;

  void assertFail(mlir::RewriterBase &rewriter, mlir::Location loc, llvm::StringRef message,
                  llvm::StringRef file, llvm::StringRef func, int line) const override;

  int getSharedAddressSpace() const override;

  int getAddressSpace(mlir::Attribute addressSpace) const override;

  bool supportVectorizedAtomics() const override;

  int getPtxVersion() const { return ptxVersion; }

private:
  int computeCapability;
  int ptxVersion;
};

} // namespace mlir::triton::NVIDIA

#endif // TRITON_CONVERSION_TRITONGPU_TO_LLVM_TARGETINFONVIDIA_H