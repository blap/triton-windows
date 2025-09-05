#pragma once
#include "mlir/IR/Types.h"
#include "mlir/IR/Attributes.h"
#include "mlir/IR/Location.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "triton/Dialect/Triton/IR/Dialect.h"
#include "triton/Dialect/TritonGPU/IR/Attributes.h"
#include "triton/Dialect/TritonGPU/IR/Dialect.h"
#include "triton/Dialect/TritonGPU/IR/TritonGPUInterfaces.h"
#include "llvm/Support/Casting.h"

// Add missing namespace declarations
namespace mlir {
class Value;
class Operation;
class OpBuilder;
class Location;
class Attribute;
namespace triton {
namespace gpu {
class CTALayoutAttr;
class SharedEncodingTrait;
} // namespace gpu
} // namespace triton
} // namespace mlir

// Add missing type declarations
using namespace mlir;
using namespace mlir::triton;
using namespace mlir::triton::gpu;

namespace mlir {
namespace triton {
namespace nvidia_gpu {

constexpr inline int TMA_SIZE_BYTES = 128;
constexpr inline int TMA_ALIGN = 128;

inline bool isFp4Padded(Attribute encoding) {
  auto mmaEnc = dyn_cast<gpu::NVMMASharedEncodingAttr>(encoding);
  return mmaEnc && mmaEnc.getFp4Padded();
}

SmallVector<Value> translateTMAIndices(OpBuilder &builder, Location loc,
                                       Attribute encoding,
                                       SmallVector<Value> indices);

gpu::CTALayoutAttr updateCTALayoutForShape(gpu::CTALayoutAttr ctaLayout,
                                           ArrayRef<int64_t> shape);

gpu::SharedEncodingTrait
updateEncodingForShape(Operation *op, gpu::SharedEncodingTrait encoding,
                       RankedTensorType tensorType);

triton::gpu::SharedEncodingTrait
getEncodingFromDescriptor(Operation *op, RankedTensorType tensorType,
                          Value desc);

SmallVector<int64_t> getTMABlockShape(ArrayRef<int64_t> shapePerCTA,
                                      int elementBitWidth, int swizzleBytes,
                                      bool fp4Padded, bool transposed,
                                      bool packedSize);

inline SmallVector<int64_t> getTMABlockShape(Attribute encoding,
                                             ArrayRef<int64_t> shapePerCTA,
                                             bool packedSize) {
  auto mmaEnc = cast<gpu::NVMMASharedEncodingAttr>(encoding);
  return getTMABlockShape(shapePerCTA, mmaEnc.getElementBitWidth(),
                          mmaEnc.getSwizzlingByteWidth(), mmaEnc.getFp4Padded(),
                          mmaEnc.getTransposed(), packedSize);
}

inline SmallVector<int64_t> getTMABlockShape(RankedTensorType ty,
                                             bool packedSize) {
  auto shapePerCTA = gpu::getShapePerCTA(ty);
  return getTMABlockShape(ty.getEncoding(), shapePerCTA, packedSize);
}

inline SmallVector<int64_t> getTMABlockShape(triton::gpu::MemDescType ty,
                                             bool packedSize) {
  auto shapePerCTA = gpu::getShapePerCTA(ty);
  return getTMABlockShape(ty.getEncoding(), shapePerCTA, packedSize);
}

std::optional<int> getTMASwizzleMode(Operation *op, TensorDescType ty);

std::optional<int> getTMAElementType(Operation *op, TensorDescType ty);

LogicalResult createTMADesc(Value tmaPtr, MakeTensorDescOp op,
                            OpBuilder &builder);

} // namespace nvidia_gpu
} // namespace triton
} // namespace mlir