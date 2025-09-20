// Copyright (c) 2023 NVIDIA Corporation & Affiliates. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files
// (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#ifndef NVGPU_ATTRDEFS
#define NVGPU_ATTRDEFS

include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/EnumAttr.td"
include "NVGPUDialect.td"

// Define the MemSemantic enum
def NVGPU_MemSemantic : I32EnumAttr<
    "NVGPUMemSemantic", "",
    [
      I32EnumAttrCase<"RELAXED", 1, "relaxed">,
      I32EnumAttrCase<"ACQUIRE", 2, "acquire">,
      I32EnumAttrCase<"RELEASE", 3, "release">,
      I32EnumAttrCase<"ACQUIRE_RELEASE", 4, "acq_rel">,
    ]> {
    let genSpecializedAttr = 0;
    let cppNamespace = "::mlir::triton::nvgpu";
}

// Define the MemSyncScope enum
def NVGPU_MemSyncScope : I32EnumAttr<
    "NVGPUMemSyncScope", "",
    [
      I32EnumAttrCase<"GPU", 1, "gpu">,
      I32EnumAttrCase<"CTA", 2, "cta">,
      I32EnumAttrCase<"SYSTEM", 3, "sys">,
    ]> {
    let genSpecializedAttr = 0;
    let cppNamespace = "::mlir::triton::nvgpu";
}

// Define the WGMMA Layout enum
def WGMMA_Layout : I32EnumAttr<"WGMMALayout",
    "wgmma layout, either 'row' or 'col'",
    [
      I32EnumAttrCase<"row", 0>,
      I32EnumAttrCase<"col", 1>
    ]>{
  let genSpecializedAttr = 0;
  let cppNamespace = "::mlir::triton::nvgpu";
}

// Define the WGMMA Element Type enum
def WGMMA_EltType : I32EnumAttr<"WGMMAEltType",
    "wgmma operand type, either 's8', 's32', 'e4m3', 'e5m2', 'f16', 'bf16', 'tf32', or 'f32'",
    [
      I32EnumAttrCase<"s8", 0>,
      I32EnumAttrCase<"s32", 1>,
      I32EnumAttrCase<"e4m3", 2>,
      I32EnumAttrCase<"e5m2", 3>,
      I32EnumAttrCase<"f16", 4>,
      I32EnumAttrCase<"bf16", 5>,
      I32EnumAttrCase<"tf32", 6>,
      I32EnumAttrCase<"f32", 7>
    ]>{
  let genSpecializedAttr = 0;
  let cppNamespace = "::mlir::triton::nvgpu";
}

// Define the actual attributes that wrap the enums
// These attributes wrap the enums defined above

def NVGPU_MemSemanticAttr : EnumAttr<NVGPU_Dialect, NVGPU_MemSemantic>;

def NVGPU_MemSyncScopeAttr : EnumAttr<NVGPU_Dialect, NVGPU_MemSyncScope>;

def WGMMA_LayoutAttr : EnumAttr<NVGPU_Dialect, WGMMA_Layout>;

def WGMMA_EltTypeAttr : EnumAttr<NVGPU_Dialect, WGMMA_EltType>;

#endif
