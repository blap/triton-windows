#ifndef TRITON_DIALECT_NVGPU_IR_ATTRIBUTES_H_
#define TRITON_DIALECT_NVGPU_IR_ATTRIBUTES_H_

#include "mlir/IR/Attributes.h"

// Include only the attribute declarations
#define GET_ATTRDEF_CLASSES
// Try to include from build directory first, then from source directory
#ifdef __has_include
#  if __has_include("NVGPUAttrDefs.h.inc")
#    include "NVGPUAttrDefs.h.inc"
#  elif __has_include("../../../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/NVGPUAttrDefs.h.inc")
#    include "../../../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/NVGPUAttrDefs.h.inc"
#  elif __has_include("../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/NVGPUAttrDefs.h.inc")
#    include "../../../build_vs/third_party/nvidia/include/Dialect/NVGPU/IR/NVGPUAttrDefs.h.inc"
#  else
#    include "NVGPUAttrDefs.h.inc"
#  endif
#else
#  include "NVGPUAttrDefs.h.inc"
#endif

#endif // TRITON_DIALECT_NVGPU_IR_ATTRIBUTES_H_