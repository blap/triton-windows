/*===- TableGen'erated file -------------------------------------*- C++ -*-===*\
|*                                                                            *|
|* AttrDef Definitions                                                        *|
|*                                                                            *|
|* Automatically generated file, do not edit!                                 *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

#ifdef GET_ATTRDEF_LIST
#undef GET_ATTRDEF_LIST

::mlir::triton::nvgpu::NVGPUMemSemanticAttr,
::mlir::triton::nvgpu::NVGPUMemSyncScopeAttr,
::mlir::triton::nvgpu::WGMMALayoutAttr,
::mlir::triton::nvgpu::WGMMAEltTypeAttr

#endif  // GET_ATTRDEF_LIST

#ifdef GET_ATTRDEF_CLASSES
#undef GET_ATTRDEF_CLASSES

static ::mlir::OptionalParseResult generatedAttributeParser(::mlir::AsmParser &parser, ::llvm::StringRef *mnemonic, ::mlir::Type type, ::mlir::Attribute &value) {
  return ::mlir::AsmParser::KeywordSwitch<::mlir::OptionalParseResult>(parser)
    .Case(::mlir::triton::nvgpu::NVGPUMemSemanticAttr::getMnemonic(), [&](llvm::StringRef, llvm::SMLoc) {
      value = ::mlir::triton::nvgpu::NVGPUMemSemanticAttr::parse(parser, type);
      return ::mlir::success(!!value);
    })
    .Case(::mlir::triton::nvgpu::NVGPUMemSyncScopeAttr::getMnemonic(), [&](llvm::StringRef, llvm::SMLoc) {
      value = ::mlir::triton::nvgpu::NVGPUMemSyncScopeAttr::parse(parser, type);
      return ::mlir::success(!!value);
    })
    .Case(::mlir::triton::nvgpu::WGMMALayoutAttr::getMnemonic(), [&](llvm::StringRef, llvm::SMLoc) {
      value = ::mlir::triton::nvgpu::WGMMALayoutAttr::parse(parser, type);
      return ::mlir::success(!!value);
    })
    .Case(::mlir::triton::nvgpu::WGMMAEltTypeAttr::getMnemonic(), [&](llvm::StringRef, llvm::SMLoc) {
      value = ::mlir::triton::nvgpu::WGMMAEltTypeAttr::parse(parser, type);
      return ::mlir::success(!!value);
    })
    .Default([&](llvm::StringRef keyword, llvm::SMLoc) {
      *mnemonic = keyword;
      return std::nullopt;
    });
}

static ::llvm::LogicalResult generatedAttributePrinter(::mlir::Attribute def, ::mlir::AsmPrinter &printer) {
  return ::llvm::TypeSwitch<::mlir::Attribute, ::llvm::LogicalResult>(def)    .Case<::mlir::triton::nvgpu::NVGPUMemSemanticAttr>([&](auto t) {
      printer << ::mlir::triton::nvgpu::NVGPUMemSemanticAttr::getMnemonic();
t.print(printer);
      return ::mlir::success();
    })
    .Case<::mlir::triton::nvgpu::NVGPUMemSyncScopeAttr>([&](auto t) {
      printer << ::mlir::triton::nvgpu::NVGPUMemSyncScopeAttr::getMnemonic();
t.print(printer);
      return ::mlir::success();
    })
    .Case<::mlir::triton::nvgpu::WGMMALayoutAttr>([&](auto t) {
      printer << ::mlir::triton::nvgpu::WGMMALayoutAttr::getMnemonic();
t.print(printer);
      return ::mlir::success();
    })
    .Case<::mlir::triton::nvgpu::WGMMAEltTypeAttr>([&](auto t) {
      printer << ::mlir::triton::nvgpu::WGMMAEltTypeAttr::getMnemonic();
t.print(printer);
      return ::mlir::success();
    })
    .Default([](auto) { return ::mlir::failure(); });
}

namespace mlir {
namespace triton {
namespace nvgpu {
namespace detail {
struct NVGPUMemSemanticAttrStorage : public ::mlir::AttributeStorage {
  using KeyTy = std::tuple<::mlir::triton::nvgpu::NVGPUMemSemantic>;
  NVGPUMemSemanticAttrStorage(::mlir::triton::nvgpu::NVGPUMemSemantic value) : value(std::move(value)) {}

  KeyTy getAsKey() const {
    return KeyTy(value);
  }

  bool operator==(const KeyTy &tblgenKey) const {
    return (value == std::get<0>(tblgenKey));
  }

  static ::llvm::hash_code hashKey(const KeyTy &tblgenKey) {
    return ::llvm::hash_combine(std::get<0>(tblgenKey));
  }

  static NVGPUMemSemanticAttrStorage *construct(::mlir::AttributeStorageAllocator &allocator, KeyTy &&tblgenKey) {
    auto value = std::move(std::get<0>(tblgenKey));
    return new (allocator.allocate<NVGPUMemSemanticAttrStorage>()) NVGPUMemSemanticAttrStorage(std::move(value));
  }

  ::mlir::triton::nvgpu::NVGPUMemSemantic value;
};
} // namespace detail
NVGPUMemSemanticAttr NVGPUMemSemanticAttr::get(::mlir::MLIRContext *context, ::mlir::triton::nvgpu::NVGPUMemSemantic value) {
  return Base::get(context, std::move(value));
}

::mlir::Attribute NVGPUMemSemanticAttr::parse(::mlir::AsmParser &odsParser, ::mlir::Type odsType) {
  ::mlir::Builder odsBuilder(odsParser.getContext());
  ::llvm::SMLoc odsLoc = odsParser.getCurrentLocation();
  (void) odsLoc;
  ::mlir::FailureOr<::mlir::triton::nvgpu::NVGPUMemSemantic> _result_value;

  // Parse variable 'value'
  _result_value = [&]() -> ::mlir::FailureOr<::mlir::triton::nvgpu::NVGPUMemSemantic> {
      auto loc = odsParser.getCurrentLocation();
      ::llvm::StringRef enumKeyword;
      if (::mlir::failed(odsParser.parseKeyword(&enumKeyword)))
        return ::mlir::failure();
      auto maybeEnum = ::mlir::triton::nvgpu::symbolizeNVGPUMemSemantic(enumKeyword);
      if (maybeEnum)
        return *maybeEnum;
      return {(::llvm::LogicalResult)(odsParser.emitError(loc) << "expected " << "::mlir::triton::nvgpu::NVGPUMemSemantic" << " to be one of: " << "relaxed" << ", " << "acquire" << ", " << "release" << ", " << "acq_rel")};
    }();
  if (::mlir::failed(_result_value)) {
    odsParser.emitError(odsParser.getCurrentLocation(), "failed to parse NVGPU_MemSemanticAttr parameter 'value' which is to be a `::mlir::triton::nvgpu::NVGPUMemSemantic`");
    return {};
  }
  assert(::mlir::succeeded(_result_value));
  return NVGPUMemSemanticAttr::get(odsParser.getContext(),
      ::mlir::triton::nvgpu::NVGPUMemSemantic((*_result_value)));
}

void NVGPUMemSemanticAttr::print(::mlir::AsmPrinter &odsPrinter) const {
  ::mlir::Builder odsBuilder(getContext());
  odsPrinter << ' ';
  odsPrinter << stringifyNVGPUMemSemantic(getValue());
}

::mlir::triton::nvgpu::NVGPUMemSemantic NVGPUMemSemanticAttr::getValue() const {
  return getImpl()->value;
}

} // namespace nvgpu
} // namespace triton
} // namespace mlir
MLIR_DEFINE_EXPLICIT_TYPE_ID(::mlir::triton::nvgpu::NVGPUMemSemanticAttr)
namespace mlir {
namespace triton {
namespace nvgpu {
namespace detail {
struct NVGPUMemSyncScopeAttrStorage : public ::mlir::AttributeStorage {
  using KeyTy = std::tuple<::mlir::triton::nvgpu::NVGPUMemSyncScope>;
  NVGPUMemSyncScopeAttrStorage(::mlir::triton::nvgpu::NVGPUMemSyncScope value) : value(std::move(value)) {}

  KeyTy getAsKey() const {
    return KeyTy(value);
  }

  bool operator==(const KeyTy &tblgenKey) const {
    return (value == std::get<0>(tblgenKey));
  }

  static ::llvm::hash_code hashKey(const KeyTy &tblgenKey) {
    return ::llvm::hash_combine(std::get<0>(tblgenKey));
  }

  static NVGPUMemSyncScopeAttrStorage *construct(::mlir::AttributeStorageAllocator &allocator, KeyTy &&tblgenKey) {
    auto value = std::move(std::get<0>(tblgenKey));
    return new (allocator.allocate<NVGPUMemSyncScopeAttrStorage>()) NVGPUMemSyncScopeAttrStorage(std::move(value));
  }

  ::mlir::triton::nvgpu::NVGPUMemSyncScope value;
};
} // namespace detail
NVGPUMemSyncScopeAttr NVGPUMemSyncScopeAttr::get(::mlir::MLIRContext *context, ::mlir::triton::nvgpu::NVGPUMemSyncScope value) {
  return Base::get(context, std::move(value));
}

::mlir::Attribute NVGPUMemSyncScopeAttr::parse(::mlir::AsmParser &odsParser, ::mlir::Type odsType) {
  ::mlir::Builder odsBuilder(odsParser.getContext());
  ::llvm::SMLoc odsLoc = odsParser.getCurrentLocation();
  (void) odsLoc;
  ::mlir::FailureOr<::mlir::triton::nvgpu::NVGPUMemSyncScope> _result_value;

  // Parse variable 'value'
  _result_value = [&]() -> ::mlir::FailureOr<::mlir::triton::nvgpu::NVGPUMemSyncScope> {
      auto loc = odsParser.getCurrentLocation();
      ::llvm::StringRef enumKeyword;
      if (::mlir::failed(odsParser.parseKeyword(&enumKeyword)))
        return ::mlir::failure();
      auto maybeEnum = ::mlir::triton::nvgpu::symbolizeNVGPUMemSyncScope(enumKeyword);
      if (maybeEnum)
        return *maybeEnum;
      return {(::llvm::LogicalResult)(odsParser.emitError(loc) << "expected " << "::mlir::triton::nvgpu::NVGPUMemSyncScope" << " to be one of: " << "gpu" << ", " << "cta" << ", " << "sys")};
    }();
  if (::mlir::failed(_result_value)) {
    odsParser.emitError(odsParser.getCurrentLocation(), "failed to parse NVGPU_MemSyncScopeAttr parameter 'value' which is to be a `::mlir::triton::nvgpu::NVGPUMemSyncScope`");
    return {};
  }
  assert(::mlir::succeeded(_result_value));
  return NVGPUMemSyncScopeAttr::get(odsParser.getContext(),
      ::mlir::triton::nvgpu::NVGPUMemSyncScope((*_result_value)));
}

void NVGPUMemSyncScopeAttr::print(::mlir::AsmPrinter &odsPrinter) const {
  ::mlir::Builder odsBuilder(getContext());
  odsPrinter << ' ';
  odsPrinter << stringifyNVGPUMemSyncScope(getValue());
}

::mlir::triton::nvgpu::NVGPUMemSyncScope NVGPUMemSyncScopeAttr::getValue() const {
  return getImpl()->value;
}

} // namespace nvgpu
} // namespace triton
} // namespace mlir
MLIR_DEFINE_EXPLICIT_TYPE_ID(::mlir::triton::nvgpu::NVGPUMemSyncScopeAttr)
namespace mlir {
namespace triton {
namespace nvgpu {
namespace detail {
struct WGMMALayoutAttrStorage : public ::mlir::AttributeStorage {
  using KeyTy = std::tuple<::mlir::triton::nvgpu::WGMMALayout>;
  WGMMALayoutAttrStorage(::mlir::triton::nvgpu::WGMMALayout value) : value(std::move(value)) {}

  KeyTy getAsKey() const {
    return KeyTy(value);
  }

  bool operator==(const KeyTy &tblgenKey) const {
    return (value == std::get<0>(tblgenKey));
  }

  static ::llvm::hash_code hashKey(const KeyTy &tblgenKey) {
    return ::llvm::hash_combine(std::get<0>(tblgenKey));
  }

  static WGMMALayoutAttrStorage *construct(::mlir::AttributeStorageAllocator &allocator, KeyTy &&tblgenKey) {
    auto value = std::move(std::get<0>(tblgenKey));
    return new (allocator.allocate<WGMMALayoutAttrStorage>()) WGMMALayoutAttrStorage(std::move(value));
  }

  ::mlir::triton::nvgpu::WGMMALayout value;
};
} // namespace detail
WGMMALayoutAttr WGMMALayoutAttr::get(::mlir::MLIRContext *context, ::mlir::triton::nvgpu::WGMMALayout value) {
  return Base::get(context, std::move(value));
}

::mlir::Attribute WGMMALayoutAttr::parse(::mlir::AsmParser &odsParser, ::mlir::Type odsType) {
  ::mlir::Builder odsBuilder(odsParser.getContext());
  ::llvm::SMLoc odsLoc = odsParser.getCurrentLocation();
  (void) odsLoc;
  ::mlir::FailureOr<::mlir::triton::nvgpu::WGMMALayout> _result_value;

  // Parse variable 'value'
  _result_value = [&]() -> ::mlir::FailureOr<::mlir::triton::nvgpu::WGMMALayout> {
      auto loc = odsParser.getCurrentLocation();
      ::llvm::StringRef enumKeyword;
      if (::mlir::failed(odsParser.parseKeyword(&enumKeyword)))
        return ::mlir::failure();
      auto maybeEnum = ::mlir::triton::nvgpu::symbolizeWGMMALayout(enumKeyword);
      if (maybeEnum)
        return *maybeEnum;
      return {(::llvm::LogicalResult)(odsParser.emitError(loc) << "expected " << "::mlir::triton::nvgpu::WGMMALayout" << " to be one of: " << "row" << ", " << "col")};
    }();
  if (::mlir::failed(_result_value)) {
    odsParser.emitError(odsParser.getCurrentLocation(), "failed to parse WGMMA_LayoutAttr parameter 'value' which is to be a `::mlir::triton::nvgpu::WGMMALayout`");
    return {};
  }
  assert(::mlir::succeeded(_result_value));
  return WGMMALayoutAttr::get(odsParser.getContext(),
      ::mlir::triton::nvgpu::WGMMALayout((*_result_value)));
}

void WGMMALayoutAttr::print(::mlir::AsmPrinter &odsPrinter) const {
  ::mlir::Builder odsBuilder(getContext());
  odsPrinter << ' ';
  odsPrinter << stringifyWGMMALayout(getValue());
}

::mlir::triton::nvgpu::WGMMALayout WGMMALayoutAttr::getValue() const {
  return getImpl()->value;
}

} // namespace nvgpu
} // namespace triton
} // namespace mlir
MLIR_DEFINE_EXPLICIT_TYPE_ID(::mlir::triton::nvgpu::WGMMALayoutAttr)
namespace mlir {
namespace triton {
namespace nvgpu {
namespace detail {
struct WGMMAEltTypeAttrStorage : public ::mlir::AttributeStorage {
  using KeyTy = std::tuple<::mlir::triton::nvgpu::WGMMAEltType>;
  WGMMAEltTypeAttrStorage(::mlir::triton::nvgpu::WGMMAEltType value) : value(std::move(value)) {}

  KeyTy getAsKey() const {
    return KeyTy(value);
  }

  bool operator==(const KeyTy &tblgenKey) const {
    return (value == std::get<0>(tblgenKey));
  }

  static ::llvm::hash_code hashKey(const KeyTy &tblgenKey) {
    return ::llvm::hash_combine(std::get<0>(tblgenKey));
  }

  static WGMMAEltTypeAttrStorage *construct(::mlir::AttributeStorageAllocator &allocator, KeyTy &&tblgenKey) {
    auto value = std::move(std::get<0>(tblgenKey));
    return new (allocator.allocate<WGMMAEltTypeAttrStorage>()) WGMMAEltTypeAttrStorage(std::move(value));
  }

  ::mlir::triton::nvgpu::WGMMAEltType value;
};
} // namespace detail
WGMMAEltTypeAttr WGMMAEltTypeAttr::get(::mlir::MLIRContext *context, ::mlir::triton::nvgpu::WGMMAEltType value) {
  return Base::get(context, std::move(value));
}

::mlir::Attribute WGMMAEltTypeAttr::parse(::mlir::AsmParser &odsParser, ::mlir::Type odsType) {
  ::mlir::Builder odsBuilder(odsParser.getContext());
  ::llvm::SMLoc odsLoc = odsParser.getCurrentLocation();
  (void) odsLoc;
  ::mlir::FailureOr<::mlir::triton::nvgpu::WGMMAEltType> _result_value;

  // Parse variable 'value'
  _result_value = [&]() -> ::mlir::FailureOr<::mlir::triton::nvgpu::WGMMAEltType> {
      auto loc = odsParser.getCurrentLocation();
      ::llvm::StringRef enumKeyword;
      if (::mlir::failed(odsParser.parseKeyword(&enumKeyword)))
        return ::mlir::failure();
      auto maybeEnum = ::mlir::triton::nvgpu::symbolizeWGMMAEltType(enumKeyword);
      if (maybeEnum)
        return *maybeEnum;
      return {(::llvm::LogicalResult)(odsParser.emitError(loc) << "expected " << "::mlir::triton::nvgpu::WGMMAEltType" << " to be one of: " << "s8" << ", " << "s32" << ", " << "e4m3" << ", " << "e5m2" << ", " << "f16" << ", " << "bf16" << ", " << "tf32" << ", " << "f32")};
    }();
  if (::mlir::failed(_result_value)) {
    odsParser.emitError(odsParser.getCurrentLocation(), "failed to parse WGMMA_EltTypeAttr parameter 'value' which is to be a `::mlir::triton::nvgpu::WGMMAEltType`");
    return {};
  }
  assert(::mlir::succeeded(_result_value));
  return WGMMAEltTypeAttr::get(odsParser.getContext(),
      ::mlir::triton::nvgpu::WGMMAEltType((*_result_value)));
}

void WGMMAEltTypeAttr::print(::mlir::AsmPrinter &odsPrinter) const {
  ::mlir::Builder odsBuilder(getContext());
  odsPrinter << ' ';
  odsPrinter << stringifyWGMMAEltType(getValue());
}

::mlir::triton::nvgpu::WGMMAEltType WGMMAEltTypeAttr::getValue() const {
  return getImpl()->value;
}

} // namespace nvgpu
} // namespace triton
} // namespace mlir
MLIR_DEFINE_EXPLICIT_TYPE_ID(::mlir::triton::nvgpu::WGMMAEltTypeAttr)

#endif  // GET_ATTRDEF_CLASSES

