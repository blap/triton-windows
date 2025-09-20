/*===- TableGen'erated file -------------------------------------*- C++ -*-===*\
|*                                                                            *|
|* AttrDef Declarations                                                       *|
|*                                                                            *|
|* Automatically generated file, do not edit!                                 *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

#ifdef GET_ATTRDEF_CLASSES
#undef GET_ATTRDEF_CLASSES


namespace mlir {
class AsmParser;
class AsmPrinter;
} // namespace mlir
namespace mlir {
namespace triton {
namespace nvgpu {
/// allowed 32-bit signless integer cases: 1, 2, 3, 4
class NVGPUMemSemanticAttr;
/// allowed 32-bit signless integer cases: 1, 2, 3
class NVGPUMemSyncScopeAttr;
/// wgmma layout, either 'row' or 'col'
class WGMMALayoutAttr;
/// wgmma operand type, either 's8', 's32', 'e4m3', 'e5m2', 'f16', 'bf16', 'tf32', or 'f32'
class WGMMAEltTypeAttr;
namespace detail {
struct NVGPUMemSemanticAttrStorage;
} // namespace detail
class NVGPUMemSemanticAttr : public ::mlir::Attribute::AttrBase<NVGPUMemSemanticAttr, ::mlir::Attribute, detail::NVGPUMemSemanticAttrStorage> {
public:
  using Base::Base;
  static constexpr ::llvm::StringLiteral name = "nvgpu.";
  static constexpr ::llvm::StringLiteral dialectName = "nvgpu";
  static NVGPUMemSemanticAttr get(::mlir::MLIRContext *context, ::mlir::triton::nvgpu::NVGPUMemSemantic value);
  static constexpr ::llvm::StringLiteral getMnemonic() {
    return {""};
  }

  static ::mlir::Attribute parse(::mlir::AsmParser &odsParser, ::mlir::Type odsType);
  void print(::mlir::AsmPrinter &odsPrinter) const;
  ::mlir::triton::nvgpu::NVGPUMemSemantic getValue() const;
};
namespace detail {
struct NVGPUMemSyncScopeAttrStorage;
} // namespace detail
class NVGPUMemSyncScopeAttr : public ::mlir::Attribute::AttrBase<NVGPUMemSyncScopeAttr, ::mlir::Attribute, detail::NVGPUMemSyncScopeAttrStorage> {
public:
  using Base::Base;
  static constexpr ::llvm::StringLiteral name = "nvgpu.";
  static constexpr ::llvm::StringLiteral dialectName = "nvgpu";
  static NVGPUMemSyncScopeAttr get(::mlir::MLIRContext *context, ::mlir::triton::nvgpu::NVGPUMemSyncScope value);
  static constexpr ::llvm::StringLiteral getMnemonic() {
    return {""};
  }

  static ::mlir::Attribute parse(::mlir::AsmParser &odsParser, ::mlir::Type odsType);
  void print(::mlir::AsmPrinter &odsPrinter) const;
  ::mlir::triton::nvgpu::NVGPUMemSyncScope getValue() const;
};
namespace detail {
struct WGMMALayoutAttrStorage;
} // namespace detail
class WGMMALayoutAttr : public ::mlir::Attribute::AttrBase<WGMMALayoutAttr, ::mlir::Attribute, detail::WGMMALayoutAttrStorage> {
public:
  using Base::Base;
  static constexpr ::llvm::StringLiteral name = "nvgpu.";
  static constexpr ::llvm::StringLiteral dialectName = "nvgpu";
  static WGMMALayoutAttr get(::mlir::MLIRContext *context, ::mlir::triton::nvgpu::WGMMALayout value);
  static constexpr ::llvm::StringLiteral getMnemonic() {
    return {""};
  }

  static ::mlir::Attribute parse(::mlir::AsmParser &odsParser, ::mlir::Type odsType);
  void print(::mlir::AsmPrinter &odsPrinter) const;
  ::mlir::triton::nvgpu::WGMMALayout getValue() const;
};
namespace detail {
struct WGMMAEltTypeAttrStorage;
} // namespace detail
class WGMMAEltTypeAttr : public ::mlir::Attribute::AttrBase<WGMMAEltTypeAttr, ::mlir::Attribute, detail::WGMMAEltTypeAttrStorage> {
public:
  using Base::Base;
  static constexpr ::llvm::StringLiteral name = "nvgpu.";
  static constexpr ::llvm::StringLiteral dialectName = "nvgpu";
  static WGMMAEltTypeAttr get(::mlir::MLIRContext *context, ::mlir::triton::nvgpu::WGMMAEltType value);
  static constexpr ::llvm::StringLiteral getMnemonic() {
    return {""};
  }

  static ::mlir::Attribute parse(::mlir::AsmParser &odsParser, ::mlir::Type odsType);
  void print(::mlir::AsmPrinter &odsPrinter) const;
  ::mlir::triton::nvgpu::WGMMAEltType getValue() const;
};
} // namespace nvgpu
} // namespace triton
} // namespace mlir
MLIR_DECLARE_EXPLICIT_TYPE_ID(::mlir::triton::nvgpu::NVGPUMemSemanticAttr)
MLIR_DECLARE_EXPLICIT_TYPE_ID(::mlir::triton::nvgpu::NVGPUMemSyncScopeAttr)
MLIR_DECLARE_EXPLICIT_TYPE_ID(::mlir::triton::nvgpu::WGMMALayoutAttr)
MLIR_DECLARE_EXPLICIT_TYPE_ID(::mlir::triton::nvgpu::WGMMAEltTypeAttr)

#endif  // GET_ATTRDEF_CLASSES

