/*===- TableGen'erated file -------------------------------------*- C++ -*-===*\
|*                                                                            *|
|* Enum Utility Declarations                                                  *|
|*                                                                            *|
|* Automatically generated file, do not edit!                                 *|
|* From: NVGPUOps.td                                                          *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

namespace mlir {
namespace triton {
namespace nvgpu {
// allowed 32-bit signless integer cases: 1, 2, 3, 4
enum class NVGPUMemSemantic : uint32_t {
  RELAXED = 1,
  ACQUIRE = 2,
  RELEASE = 3,
  ACQUIRE_RELEASE = 4,
};

::std::optional<NVGPUMemSemantic> symbolizeNVGPUMemSemantic(uint32_t);
::llvm::StringRef stringifyNVGPUMemSemantic(NVGPUMemSemantic);
::std::optional<NVGPUMemSemantic> symbolizeNVGPUMemSemantic(::llvm::StringRef);
inline constexpr unsigned getMaxEnumValForNVGPUMemSemantic() {
  return 4;
}


inline ::llvm::StringRef stringifyEnum(NVGPUMemSemantic enumValue) {
  return stringifyNVGPUMemSemantic(enumValue);
}

template <typename EnumType>
::std::optional<EnumType> symbolizeEnum(::llvm::StringRef);

template <>
inline ::std::optional<NVGPUMemSemantic> symbolizeEnum<NVGPUMemSemantic>(::llvm::StringRef str) {
  return symbolizeNVGPUMemSemantic(str);
}

class NVGPUMemSemanticAttr : public ::mlir::IntegerAttr {
public:
  using ValueType = NVGPUMemSemantic;
  using ::mlir::IntegerAttr::IntegerAttr;
  static bool classof(::mlir::Attribute attr);
  static NVGPUMemSemanticAttr get(::mlir::MLIRContext *context, NVGPUMemSemantic val);
  NVGPUMemSemantic getValue() const;
};
} // namespace nvgpu
} // namespace triton
} // namespace mlir

namespace mlir {
template <typename T, typename>
struct FieldParser;

template<>
struct FieldParser<::mlir::triton::nvgpu::NVGPUMemSemantic, ::mlir::triton::nvgpu::NVGPUMemSemantic> {
  template <typename ParserT>
  static FailureOr<::mlir::triton::nvgpu::NVGPUMemSemantic> parse(ParserT &parser) {
    // Parse the keyword/string containing the enum.
    std::string enumKeyword;
    auto loc = parser.getCurrentLocation();
    if (failed(parser.parseOptionalKeywordOrString(&enumKeyword)))
      return parser.emitError(loc, "expected keyword for allowed 32-bit signless integer cases: 1, 2, 3, 4");

    // Symbolize the keyword.
    if (::std::optional<::mlir::triton::nvgpu::NVGPUMemSemantic> attr = ::mlir::triton::nvgpu::symbolizeEnum<::mlir::triton::nvgpu::NVGPUMemSemantic>(enumKeyword))
      return *attr;
    return parser.emitError(loc, "expected one of [relaxed, acquire, release, acq_rel] for allowed 32-bit signless integer cases: 1, 2, 3, 4, got: ") << enumKeyword;
  }
};

/// Support for std::optional, useful in attribute/type definition where the enum is
/// used as:
///
///    let parameters = (ins OptionalParameter<"std::optional<TheEnumName>">:$value);
template<>
struct FieldParser<std::optional<::mlir::triton::nvgpu::NVGPUMemSemantic>, std::optional<::mlir::triton::nvgpu::NVGPUMemSemantic>> {
  template <typename ParserT>
  static FailureOr<std::optional<::mlir::triton::nvgpu::NVGPUMemSemantic>> parse(ParserT &parser) {
    // Parse the keyword/string containing the enum.
    std::string enumKeyword;
    auto loc = parser.getCurrentLocation();
    if (failed(parser.parseOptionalKeywordOrString(&enumKeyword)))
      return std::optional<::mlir::triton::nvgpu::NVGPUMemSemantic>{};

    // Symbolize the keyword.
    if (::std::optional<::mlir::triton::nvgpu::NVGPUMemSemantic> attr = ::mlir::triton::nvgpu::symbolizeEnum<::mlir::triton::nvgpu::NVGPUMemSemantic>(enumKeyword))
      return attr;
    return parser.emitError(loc, "expected one of [relaxed, acquire, release, acq_rel] for allowed 32-bit signless integer cases: 1, 2, 3, 4, got: ") << enumKeyword;
  }
};
} // namespace mlir

namespace llvm {
inline ::llvm::raw_ostream &operator<<(::llvm::raw_ostream &p, ::mlir::triton::nvgpu::NVGPUMemSemantic value) {
  auto valueStr = stringifyEnum(value);
  return p << valueStr;
}
} // namespace llvm

namespace llvm {
template<> struct DenseMapInfo<::mlir::triton::nvgpu::NVGPUMemSemantic> {
  using StorageInfo = ::llvm::DenseMapInfo<uint32_t>;

  static inline ::mlir::triton::nvgpu::NVGPUMemSemantic getEmptyKey() {
    return static_cast<::mlir::triton::nvgpu::NVGPUMemSemantic>(StorageInfo::getEmptyKey());
  }

  static inline ::mlir::triton::nvgpu::NVGPUMemSemantic getTombstoneKey() {
    return static_cast<::mlir::triton::nvgpu::NVGPUMemSemantic>(StorageInfo::getTombstoneKey());
  }

  static unsigned getHashValue(const ::mlir::triton::nvgpu::NVGPUMemSemantic &val) {
    return StorageInfo::getHashValue(static_cast<uint32_t>(val));
  }

  static bool isEqual(const ::mlir::triton::nvgpu::NVGPUMemSemantic &lhs, const ::mlir::triton::nvgpu::NVGPUMemSemantic &rhs) {
    return lhs == rhs;
  }
};
}

namespace mlir {
namespace triton {
namespace nvgpu {
// allowed 32-bit signless integer cases: 1, 2, 3
enum class NVGPUMemSyncScope : uint32_t {
  GPU = 1,
  CTA = 2,
  SYSTEM = 3,
};

::std::optional<NVGPUMemSyncScope> symbolizeNVGPUMemSyncScope(uint32_t);
::llvm::StringRef stringifyNVGPUMemSyncScope(NVGPUMemSyncScope);
::std::optional<NVGPUMemSyncScope> symbolizeNVGPUMemSyncScope(::llvm::StringRef);
inline constexpr unsigned getMaxEnumValForNVGPUMemSyncScope() {
  return 3;
}


inline ::llvm::StringRef stringifyEnum(NVGPUMemSyncScope enumValue) {
  return stringifyNVGPUMemSyncScope(enumValue);
}

template <typename EnumType>
::std::optional<EnumType> symbolizeEnum(::llvm::StringRef);

template <>
inline ::std::optional<NVGPUMemSyncScope> symbolizeEnum<NVGPUMemSyncScope>(::llvm::StringRef str) {
  return symbolizeNVGPUMemSyncScope(str);
}

class NVGPUMemSyncScopeAttr : public ::mlir::IntegerAttr {
public:
  using ValueType = NVGPUMemSyncScope;
  using ::mlir::IntegerAttr::IntegerAttr;
  static bool classof(::mlir::Attribute attr);
  static NVGPUMemSyncScopeAttr get(::mlir::MLIRContext *context, NVGPUMemSyncScope val);
  NVGPUMemSyncScope getValue() const;
};
} // namespace nvgpu
} // namespace triton
} // namespace mlir

namespace mlir {
template <typename T, typename>
struct FieldParser;

template<>
struct FieldParser<::mlir::triton::nvgpu::NVGPUMemSyncScope, ::mlir::triton::nvgpu::NVGPUMemSyncScope> {
  template <typename ParserT>
  static FailureOr<::mlir::triton::nvgpu::NVGPUMemSyncScope> parse(ParserT &parser) {
    // Parse the keyword/string containing the enum.
    std::string enumKeyword;
    auto loc = parser.getCurrentLocation();
    if (failed(parser.parseOptionalKeywordOrString(&enumKeyword)))
      return parser.emitError(loc, "expected keyword for allowed 32-bit signless integer cases: 1, 2, 3");

    // Symbolize the keyword.
    if (::std::optional<::mlir::triton::nvgpu::NVGPUMemSyncScope> attr = ::mlir::triton::nvgpu::symbolizeEnum<::mlir::triton::nvgpu::NVGPUMemSyncScope>(enumKeyword))
      return *attr;
    return parser.emitError(loc, "expected one of [gpu, cta, sys] for allowed 32-bit signless integer cases: 1, 2, 3, got: ") << enumKeyword;
  }
};

/// Support for std::optional, useful in attribute/type definition where the enum is
/// used as:
///
///    let parameters = (ins OptionalParameter<"std::optional<TheEnumName>">:$value);
template<>
struct FieldParser<std::optional<::mlir::triton::nvgpu::NVGPUMemSyncScope>, std::optional<::mlir::triton::nvgpu::NVGPUMemSyncScope>> {
  template <typename ParserT>
  static FailureOr<std::optional<::mlir::triton::nvgpu::NVGPUMemSyncScope>> parse(ParserT &parser) {
    // Parse the keyword/string containing the enum.
    std::string enumKeyword;
    auto loc = parser.getCurrentLocation();
    if (failed(parser.parseOptionalKeywordOrString(&enumKeyword)))
      return std::optional<::mlir::triton::nvgpu::NVGPUMemSyncScope>{};

    // Symbolize the keyword.
    if (::std::optional<::mlir::triton::nvgpu::NVGPUMemSyncScope> attr = ::mlir::triton::nvgpu::symbolizeEnum<::mlir::triton::nvgpu::NVGPUMemSyncScope>(enumKeyword))
      return attr;
    return parser.emitError(loc, "expected one of [gpu, cta, sys] for allowed 32-bit signless integer cases: 1, 2, 3, got: ") << enumKeyword;
  }
};
} // namespace mlir

namespace llvm {
inline ::llvm::raw_ostream &operator<<(::llvm::raw_ostream &p, ::mlir::triton::nvgpu::NVGPUMemSyncScope value) {
  auto valueStr = stringifyEnum(value);
  return p << valueStr;
}
} // namespace llvm

namespace llvm {
template<> struct DenseMapInfo<::mlir::triton::nvgpu::NVGPUMemSyncScope> {
  using StorageInfo = ::llvm::DenseMapInfo<uint32_t>;

  static inline ::mlir::triton::nvgpu::NVGPUMemSyncScope getEmptyKey() {
    return static_cast<::mlir::triton::nvgpu::NVGPUMemSyncScope>(StorageInfo::getEmptyKey());
  }

  static inline ::mlir::triton::nvgpu::NVGPUMemSyncScope getTombstoneKey() {
    return static_cast<::mlir::triton::nvgpu::NVGPUMemSyncScope>(StorageInfo::getTombstoneKey());
  }

  static unsigned getHashValue(const ::mlir::triton::nvgpu::NVGPUMemSyncScope &val) {
    return StorageInfo::getHashValue(static_cast<uint32_t>(val));
  }

  static bool isEqual(const ::mlir::triton::nvgpu::NVGPUMemSyncScope &lhs, const ::mlir::triton::nvgpu::NVGPUMemSyncScope &rhs) {
    return lhs == rhs;
  }
};
}

namespace mlir {
namespace triton {
namespace nvgpu {
// wgmma operand type, either 's8', 's32', 'e4m3', 'e5m2', 'f16', 'bf16', 'tf32', or 'f32'
enum class WGMMAEltType : uint32_t {
  s8 = 0,
  s32 = 1,
  e4m3 = 2,
  e5m2 = 3,
  f16 = 4,
  bf16 = 5,
  tf32 = 6,
  f32 = 7,
};

::std::optional<WGMMAEltType> symbolizeWGMMAEltType(uint32_t);
::llvm::StringRef stringifyWGMMAEltType(WGMMAEltType);
::std::optional<WGMMAEltType> symbolizeWGMMAEltType(::llvm::StringRef);
inline constexpr unsigned getMaxEnumValForWGMMAEltType() {
  return 7;
}


inline ::llvm::StringRef stringifyEnum(WGMMAEltType enumValue) {
  return stringifyWGMMAEltType(enumValue);
}

template <typename EnumType>
::std::optional<EnumType> symbolizeEnum(::llvm::StringRef);

template <>
inline ::std::optional<WGMMAEltType> symbolizeEnum<WGMMAEltType>(::llvm::StringRef str) {
  return symbolizeWGMMAEltType(str);
}

class WGMMAEltTypeAttr : public ::mlir::IntegerAttr {
public:
  using ValueType = WGMMAEltType;
  using ::mlir::IntegerAttr::IntegerAttr;
  static bool classof(::mlir::Attribute attr);
  static WGMMAEltTypeAttr get(::mlir::MLIRContext *context, WGMMAEltType val);
  WGMMAEltType getValue() const;
};
} // namespace nvgpu
} // namespace triton
} // namespace mlir

namespace mlir {
template <typename T, typename>
struct FieldParser;

template<>
struct FieldParser<::mlir::triton::nvgpu::WGMMAEltType, ::mlir::triton::nvgpu::WGMMAEltType> {
  template <typename ParserT>
  static FailureOr<::mlir::triton::nvgpu::WGMMAEltType> parse(ParserT &parser) {
    // Parse the keyword/string containing the enum.
    std::string enumKeyword;
    auto loc = parser.getCurrentLocation();
    if (failed(parser.parseOptionalKeywordOrString(&enumKeyword)))
      return parser.emitError(loc, "expected keyword for wgmma operand type, either 's8', 's32', 'e4m3', 'e5m2', 'f16', 'bf16', 'tf32', or 'f32'");

    // Symbolize the keyword.
    if (::std::optional<::mlir::triton::nvgpu::WGMMAEltType> attr = ::mlir::triton::nvgpu::symbolizeEnum<::mlir::triton::nvgpu::WGMMAEltType>(enumKeyword))
      return *attr;
    return parser.emitError(loc, "expected one of [s8, s32, e4m3, e5m2, f16, bf16, tf32, f32] for wgmma operand type, either 's8', 's32', 'e4m3', 'e5m2', 'f16', 'bf16', 'tf32', or 'f32', got: ") << enumKeyword;
  }
};

/// Support for std::optional, useful in attribute/type definition where the enum is
/// used as:
///
///    let parameters = (ins OptionalParameter<"std::optional<TheEnumName>">:$value);
template<>
struct FieldParser<std::optional<::mlir::triton::nvgpu::WGMMAEltType>, std::optional<::mlir::triton::nvgpu::WGMMAEltType>> {
  template <typename ParserT>
  static FailureOr<std::optional<::mlir::triton::nvgpu::WGMMAEltType>> parse(ParserT &parser) {
    // Parse the keyword/string containing the enum.
    std::string enumKeyword;
    auto loc = parser.getCurrentLocation();
    if (failed(parser.parseOptionalKeywordOrString(&enumKeyword)))
      return std::optional<::mlir::triton::nvgpu::WGMMAEltType>{};

    // Symbolize the keyword.
    if (::std::optional<::mlir::triton::nvgpu::WGMMAEltType> attr = ::mlir::triton::nvgpu::symbolizeEnum<::mlir::triton::nvgpu::WGMMAEltType>(enumKeyword))
      return attr;
    return parser.emitError(loc, "expected one of [s8, s32, e4m3, e5m2, f16, bf16, tf32, f32] for wgmma operand type, either 's8', 's32', 'e4m3', 'e5m2', 'f16', 'bf16', 'tf32', or 'f32', got: ") << enumKeyword;
  }
};
} // namespace mlir

namespace llvm {
inline ::llvm::raw_ostream &operator<<(::llvm::raw_ostream &p, ::mlir::triton::nvgpu::WGMMAEltType value) {
  auto valueStr = stringifyEnum(value);
  return p << valueStr;
}
} // namespace llvm

namespace llvm {
template<> struct DenseMapInfo<::mlir::triton::nvgpu::WGMMAEltType> {
  using StorageInfo = ::llvm::DenseMapInfo<uint32_t>;

  static inline ::mlir::triton::nvgpu::WGMMAEltType getEmptyKey() {
    return static_cast<::mlir::triton::nvgpu::WGMMAEltType>(StorageInfo::getEmptyKey());
  }

  static inline ::mlir::triton::nvgpu::WGMMAEltType getTombstoneKey() {
    return static_cast<::mlir::triton::nvgpu::WGMMAEltType>(StorageInfo::getTombstoneKey());
  }

  static unsigned getHashValue(const ::mlir::triton::nvgpu::WGMMAEltType &val) {
    return StorageInfo::getHashValue(static_cast<uint32_t>(val));
  }

  static bool isEqual(const ::mlir::triton::nvgpu::WGMMAEltType &lhs, const ::mlir::triton::nvgpu::WGMMAEltType &rhs) {
    return lhs == rhs;
  }
};
}

namespace mlir {
namespace triton {
namespace nvgpu {
// wgmma layout, either 'row' or 'col'
enum class WGMMALayout : uint32_t {
  row = 0,
  col = 1,
};

::std::optional<WGMMALayout> symbolizeWGMMALayout(uint32_t);
::llvm::StringRef stringifyWGMMALayout(WGMMALayout);
::std::optional<WGMMALayout> symbolizeWGMMALayout(::llvm::StringRef);
inline constexpr unsigned getMaxEnumValForWGMMALayout() {
  return 1;
}


inline ::llvm::StringRef stringifyEnum(WGMMALayout enumValue) {
  return stringifyWGMMALayout(enumValue);
}

template <typename EnumType>
::std::optional<EnumType> symbolizeEnum(::llvm::StringRef);

template <>
inline ::std::optional<WGMMALayout> symbolizeEnum<WGMMALayout>(::llvm::StringRef str) {
  return symbolizeWGMMALayout(str);
}

class WGMMALayoutAttr : public ::mlir::IntegerAttr {
public:
  using ValueType = WGMMALayout;
  using ::mlir::IntegerAttr::IntegerAttr;
  static bool classof(::mlir::Attribute attr);
  static WGMMALayoutAttr get(::mlir::MLIRContext *context, WGMMALayout val);
  WGMMALayout getValue() const;
};
} // namespace nvgpu
} // namespace triton
} // namespace mlir

namespace mlir {
template <typename T, typename>
struct FieldParser;

template<>
struct FieldParser<::mlir::triton::nvgpu::WGMMALayout, ::mlir::triton::nvgpu::WGMMALayout> {
  template <typename ParserT>
  static FailureOr<::mlir::triton::nvgpu::WGMMALayout> parse(ParserT &parser) {
    // Parse the keyword/string containing the enum.
    std::string enumKeyword;
    auto loc = parser.getCurrentLocation();
    if (failed(parser.parseOptionalKeywordOrString(&enumKeyword)))
      return parser.emitError(loc, "expected keyword for wgmma layout, either 'row' or 'col'");

    // Symbolize the keyword.
    if (::std::optional<::mlir::triton::nvgpu::WGMMALayout> attr = ::mlir::triton::nvgpu::symbolizeEnum<::mlir::triton::nvgpu::WGMMALayout>(enumKeyword))
      return *attr;
    return parser.emitError(loc, "expected one of [row, col] for wgmma layout, either 'row' or 'col', got: ") << enumKeyword;
  }
};

/// Support for std::optional, useful in attribute/type definition where the enum is
/// used as:
///
///    let parameters = (ins OptionalParameter<"std::optional<TheEnumName>">:$value);
template<>
struct FieldParser<std::optional<::mlir::triton::nvgpu::WGMMALayout>, std::optional<::mlir::triton::nvgpu::WGMMALayout>> {
  template <typename ParserT>
  static FailureOr<std::optional<::mlir::triton::nvgpu::WGMMALayout>> parse(ParserT &parser) {
    // Parse the keyword/string containing the enum.
    std::string enumKeyword;
    auto loc = parser.getCurrentLocation();
    if (failed(parser.parseOptionalKeywordOrString(&enumKeyword)))
      return std::optional<::mlir::triton::nvgpu::WGMMALayout>{};

    // Symbolize the keyword.
    if (::std::optional<::mlir::triton::nvgpu::WGMMALayout> attr = ::mlir::triton::nvgpu::symbolizeEnum<::mlir::triton::nvgpu::WGMMALayout>(enumKeyword))
      return attr;
    return parser.emitError(loc, "expected one of [row, col] for wgmma layout, either 'row' or 'col', got: ") << enumKeyword;
  }
};
} // namespace mlir

namespace llvm {
inline ::llvm::raw_ostream &operator<<(::llvm::raw_ostream &p, ::mlir::triton::nvgpu::WGMMALayout value) {
  auto valueStr = stringifyEnum(value);
  return p << valueStr;
}
} // namespace llvm

namespace llvm {
template<> struct DenseMapInfo<::mlir::triton::nvgpu::WGMMALayout> {
  using StorageInfo = ::llvm::DenseMapInfo<uint32_t>;

  static inline ::mlir::triton::nvgpu::WGMMALayout getEmptyKey() {
    return static_cast<::mlir::triton::nvgpu::WGMMALayout>(StorageInfo::getEmptyKey());
  }

  static inline ::mlir::triton::nvgpu::WGMMALayout getTombstoneKey() {
    return static_cast<::mlir::triton::nvgpu::WGMMALayout>(StorageInfo::getTombstoneKey());
  }

  static unsigned getHashValue(const ::mlir::triton::nvgpu::WGMMALayout &val) {
    return StorageInfo::getHashValue(static_cast<uint32_t>(val));
  }

  static bool isEqual(const ::mlir::triton::nvgpu::WGMMALayout &lhs, const ::mlir::triton::nvgpu::WGMMALayout &rhs) {
    return lhs == rhs;
  }
};
}

