set(MLIR_BINARY_DIR ${CMAKE_BINARY_DIR})

set(LLVM_TARGET_DEFINITIONS NVGPUOps.td)
mlir_tablegen(Dialect.h.inc -gen-dialect-decls -dialect=nvgpu)
mlir_tablegen(Dialect.cpp.inc -gen-dialect-defs -dialect=nvgpu)
mlir_tablegen(OpsConversions.inc -gen-llvmir-conversions)
# Comment out the enum generation to prevent conflicts
# mlir_tablegen(OpsEnums.h.inc -gen-enum-decls)
# mlir_tablegen(OpsEnums.cpp.inc -gen-enum-defs)
mlir_tablegen(Ops.h.inc -gen-op-decls)
mlir_tablegen(Ops.cpp.inc -gen-op-defs)
add_mlir_doc(NVGPUDialect NVGPUDialect dialects/ -gen-dialect-doc)
add_mlir_doc(NVGPUOps NVGPUOps dialects/ -gen-op-doc)
add_public_tablegen_target(NVGPUTableGen)

set(LLVM_TARGET_DEFINITIONS NVGPUAttrDefs.td)
mlir_tablegen(NVGPUAttrDefs.h.inc -gen-attrdef-decls)
mlir_tablegen(NVGPUAttrDefs.cpp.inc -gen-attrdef-defs)
add_public_tablegen_target(NVGPUAttrDefsIncGen)

# Comment out the enum generation to prevent conflicts
# mlir_tablegen(NVGPUOpsEnums.h.inc -gen-enum-decls)
# mlir_tablegen(NVGPUOpsEnums.cpp.inc -gen-enum-defs)
# add_public_tablegen_target(NVGPUEnumsTableGen)