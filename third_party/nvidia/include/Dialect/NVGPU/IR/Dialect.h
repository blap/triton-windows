/*
 * Copyright (c) 2023 NVIDIA Corporation & Affiliates. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#ifndef TRITON_DIALECT_NVGPU_IR_DIALECT_H_
#define TRITON_DIALECT_NVGPU_IR_DIALECT_H_

#include "mlir/Dialect/GPU/IR/GPUDialect.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Dialect.h"

// Include the dialect header first
// Try to include from build directory first, then from source directory
#ifdef __has_include
#  if __has_include("Dialect.h.inc")
#    include "Dialect.h.inc"
#  elif __has_include("../../../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/Dialect.h.inc")
#    include "../../../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/Dialect.h.inc"
#  elif __has_include("../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/Dialect.h.inc")
#    include "../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/Dialect.h.inc"
#  else
#    include "Dialect.h.inc"
#  endif
#else
#  include "Dialect.h.inc"
#endif

// Include enum declarations before the ops
#include "NVGPUEnums.h"

// Include attribute definitions
#include "Attributes.h"

#define GET_OP_CLASSES
// Try to include from build directory first, then from source directory
#ifdef __has_include
#  if __has_include("Ops.h.inc")
#    include "Ops.h.inc"
#  elif __has_include("../../../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/Ops.h.inc")
#    include "../../../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/Ops.h.inc"
#  elif __has_include("../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/Ops.h.inc")
#    include "../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/Ops.h.inc"
#  else
#    include "Ops.h.inc"
#  endif
#else
#  include "Ops.h.inc"
#endif

namespace mlir {
namespace triton {
namespace nvgpu {} // namespace nvgpu
} // namespace triton
} // namespace mlir

#endif // TRITON_DIALECT_NVGPU_IR_DIALECT_H_