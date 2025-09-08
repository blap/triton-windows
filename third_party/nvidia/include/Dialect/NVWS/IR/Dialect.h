#ifndef DIALECT_NVWS_IR_DIALECT_H_
#define DIALECT_NVWS_IR_DIALECT_H_

#include "mlir/Dialect/GPU/IR/GPUDialect.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Dialect.h"
#include "mlir/Interfaces/ControlFlowInterfaces.h"
// Updated include paths for pybind11 3.0.1 compatibility and proper CMake build support
#include "Dialect.h.inc"
#include "triton/Dialect/Triton/IR/Dialect.h"
#include "triton/Dialect/TritonGPU/IR/Attributes.h"
#include "triton/Dialect/TritonGPU/IR/Dialect.h"
#include "triton/Dialect/TritonGPU/IR/Types.h"

#define GET_ATTRDEF_CLASSES
// Updated include paths for pybind11 3.0.1 compatibility and proper CMake build support
#include "NVWSAttrDefs.h.inc"
#include "NVWSAttrEnums.h.inc"

#define GET_TYPEDEF_CLASSES
// Updated include paths for pybind11 3.0.1 compatibility and proper CMake build support
#include "Types.h.inc"

#define GET_OP_CLASSES
// Updated include paths for pybind11 3.0.1 compatibility and proper CMake build support
#include "Ops.h.inc"

namespace mlir {
namespace triton {
namespace nvws {} // namespace nvws
} // namespace triton
} // namespace mlir

#endif // DIALECT_NVWS_IR_DIALECT_H_