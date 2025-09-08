/*===- TableGen'erated file -------------------------------------*- C++ -*-===*\
|*                                                                            *|
|* TypeDef Definitions                                                        *|
|*                                                                            *|
|* Automatically generated file, do not edit!                                 *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

#ifdef GET_TYPEDEF_LIST
#undef GET_TYPEDEF_LIST

::mlir::triton::nvws::ArefType,
::mlir::triton::nvws::TokenType

#endif  // GET_TYPEDEF_LIST

#ifdef GET_TYPEDEF_CLASSES
#undef GET_TYPEDEF_CLASSES

static ::mlir::OptionalParseResult generatedTypeParser(::mlir::AsmParser &parser, ::llvm::StringRef *mnemonic, ::mlir::Type &value) {
  return ::mlir::AsmParser::KeywordSwitch<::mlir::OptionalParseResult>(parser)
    .Case(::mlir::triton::nvws::ArefType::getMnemonic(), [&](llvm::StringRef, llvm::SMLoc) {
      value = ::mlir::triton::nvws::ArefType::parse(parser);
      return ::mlir::success(!!value);
    })
    .Case(::mlir::triton::nvws::TokenType::getMnemonic(), [&](llvm::StringRef, llvm::SMLoc) {
      value = ::mlir::triton::nvws::TokenType::get(parser.getContext());
      return ::mlir::success(!!value);
    })
    .Default([&](llvm::StringRef keyword, llvm::SMLoc) {
      *mnemonic = keyword;
      return std::nullopt;
    });
}

static ::llvm::LogicalResult generatedTypePrinter(::mlir::Type def, ::mlir::AsmPrinter &printer) {
  return ::llvm::TypeSwitch<::mlir::Type, ::llvm::LogicalResult>(def)    .Case<::mlir::triton::nvws::ArefType>([&](auto t) {
      printer << ::mlir::triton::nvws::ArefType::getMnemonic();
t.print(printer);
      return ::mlir::success();
    })
    .Case<::mlir::triton::nvws::TokenType>([&](auto t) {
      printer << ::mlir::triton::nvws::TokenType::getMnemonic();
      return ::mlir::success();
    })
    .Default([](auto) { return ::mlir::failure(); });
}

namespace mlir {
namespace triton {
namespace nvws {
namespace detail {
struct ArefTypeStorage : public ::mlir::TypeStorage {
  using KeyTy = std::tuple<TypeArrayAttr, std::optional<int>>;
  ArefTypeStorage(TypeArrayAttr baseType, std::optional<int> numBatchAxes) : baseType(std::move(baseType)), numBatchAxes(std::move(numBatchAxes)) {}

  KeyTy getAsKey() const {
    return KeyTy(baseType, numBatchAxes);
  }

  bool operator==(const KeyTy &tblgenKey) const {
    return (baseType == std::get<0>(tblgenKey)) && (numBatchAxes == std::get<1>(tblgenKey));
  }

  static ::llvm::hash_code hashKey(const KeyTy &tblgenKey) {
    return ::llvm::hash_combine(std::get<0>(tblgenKey), std::get<1>(tblgenKey));
  }

  static ArefTypeStorage *construct(::mlir::TypeStorageAllocator &allocator, KeyTy &&tblgenKey) {
    auto baseType = std::move(std::get<0>(tblgenKey));
    auto numBatchAxes = std::move(std::get<1>(tblgenKey));
    return new (allocator.allocate<ArefTypeStorage>()) ArefTypeStorage(std::move(baseType), std::move(numBatchAxes));
  }

  TypeArrayAttr baseType;
  std::optional<int> numBatchAxes;
};
} // namespace detail
ArefType ArefType::get(::mlir::MLIRContext *context, TypeArrayAttr baseType, std::optional<int> numBatchAxes) {
  return Base::get(context, std::move(baseType), std::move(numBatchAxes));
}

::mlir::Type ArefType::parse(::mlir::AsmParser &odsParser) {
  ::mlir::Builder odsBuilder(odsParser.getContext());
  ::llvm::SMLoc odsLoc = odsParser.getCurrentLocation();
  (void) odsLoc;
  ::mlir::FailureOr<TypeArrayAttr> _result_baseType;
  ::mlir::FailureOr<std::optional<int>> _result_numBatchAxes;
  // Parse literal '<'
  if (odsParser.parseLess()) return {};

  // Parse variable 'baseType'
  _result_baseType = ::mlir::FieldParser<TypeArrayAttr>::parse(odsParser);
  if (::mlir::failed(_result_baseType)) {
    odsParser.emitError(odsParser.getCurrentLocation(), "failed to parse NVWS_ArefType parameter 'baseType' which is to be a `TypeArrayAttr`");
    return {};
  }
  // Parse literal ','
  if (odsParser.parseOptionalComma()) {
  } else {

    // Parse variable 'numBatchAxes'
    _result_numBatchAxes = ::mlir::FieldParser<std::optional<int>>::parse(odsParser);
    if (::mlir::failed(_result_numBatchAxes)) {
      odsParser.emitError(odsParser.getCurrentLocation(), "failed to parse NVWS_ArefType parameter 'numBatchAxes' which is to be a `std::optional<int>`");
      return {};
    }
  }
  // Parse literal '>'
  if (odsParser.parseGreater()) return {};
  assert(::mlir::succeeded(_result_baseType));
  return ArefType::get(odsParser.getContext(),
      TypeArrayAttr((*_result_baseType)),
      std::optional<int>((_result_numBatchAxes.value_or(0))));
}

void ArefType::print(::mlir::AsmPrinter &odsPrinter) const {
  ::mlir::Builder odsBuilder(getContext());
  odsPrinter << "<";
  odsPrinter.printStrippedAttrOrType(getBaseType());
  if (!(getNumBatchAxes() == 0)) {
    odsPrinter << ",";
    if (!(getNumBatchAxes() == 0)) {
      odsPrinter << ' ';
      odsPrinter.printStrippedAttrOrType(getNumBatchAxes());
    }
  } else {
  }
  odsPrinter << ">";
}

TypeArrayAttr ArefType::getBaseType() const {
  return getImpl()->baseType;
}

std::optional<int> ArefType::getNumBatchAxes() const {
  return getImpl()->numBatchAxes;
}

} // namespace nvws
} // namespace triton
} // namespace mlir
MLIR_DEFINE_EXPLICIT_TYPE_ID(::mlir::triton::nvws::ArefType)
namespace mlir {
namespace triton {
namespace nvws {
} // namespace nvws
} // namespace triton
} // namespace mlir
MLIR_DEFINE_EXPLICIT_TYPE_ID(::mlir::triton::nvws::TokenType)
namespace mlir {
namespace triton {
namespace nvws {

/// Parse a type registered to this dialect.
::mlir::Type NVWSDialect::parseType(::mlir::DialectAsmParser &parser) const {
  ::llvm::SMLoc typeLoc = parser.getCurrentLocation();
  ::llvm::StringRef mnemonic;
  ::mlir::Type genType;
  auto parseResult = generatedTypeParser(parser, &mnemonic, genType);
  if (parseResult.has_value())
    return genType;
  
  parser.emitError(typeLoc) << "unknown  type `"
      << mnemonic << "` in dialect `" << getNamespace() << "`";
  return {};
}
/// Print a type registered to this dialect.
void NVWSDialect::printType(::mlir::Type type,
                    ::mlir::DialectAsmPrinter &printer) const {
  if (::mlir::succeeded(generatedTypePrinter(type, printer)))
    return;
  
}
} // namespace nvws
} // namespace triton
} // namespace mlir

#endif  // GET_TYPEDEF_CLASSES

