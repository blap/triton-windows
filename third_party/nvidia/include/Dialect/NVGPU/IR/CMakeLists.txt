set(MLIR_BINARY_DIR ${CMAKE_BINARY_DIR})

# Set the output directory for generated files
set(LLVM_TABLEGEN_OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})

set(LLVM_TARGET_DEFINITIONS NVGPUOps.td)
mlir_tablegen(Dialect.h.inc -gen-dialect-decls -dialect=nvgpu)
mlir_tablegen(Dialect.cpp.inc -gen-dialect-defs -dialect=nvgpu)
mlir_tablegen(OpsConversions.inc -gen-llvmir-conversions)
# Generate enum files with proper namespace to avoid conflicts
mlir_tablegen(NVGPUOpsEnums.h.inc -gen-enum-decls)
mlir_tablegen(NVGPUOpsEnums.cpp.inc -gen-enum-defs)
mlir_tablegen(Ops.h.inc -gen-op-decls)
mlir_tablegen(Ops.cpp.inc -gen-op-defs)
add_mlir_doc(NVGPUDialect NVGPUDialect dialects/ -gen-dialect-doc)
add_mlir_doc(NVGPUOps NVGPUOps dialects/ -gen-op-doc)
add_public_tablegen_target(NVGPUTableGen)

set(LLVM_TARGET_DEFINITIONS NVGPUAttrDefs.td)
mlir_tablegen(NVGPUAttrDefs.h.inc -gen-attrdef-decls)
mlir_tablegen(NVGPUAttrDefs.cpp.inc -gen-attrdef-defs)
# Generate attribute enum files
mlir_tablegen(NVGPUAttrEnums.h.inc -gen-enum-decls)
mlir_tablegen(NVGPUAttrEnums.cpp.inc -gen-enum-defs)
add_public_tablegen_target(NVGPUAttrDefsIncGen)
# Make sure attribute definitions depend on enum definitions
add_dependencies(NVGPUAttrDefsIncGen NVGPUTableGen)