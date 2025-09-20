#ifndef DIALECT_NVWS_TRANSFORMS_PASSES_H_INC
#define DIALECT_NVWS_TRANSFORMS_PASSES_H_INC

#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassRegistry.h"

namespace mlir {
namespace triton {
namespace nvws {

class NVWSLowerWarpGroupBase;
class NVWSLowerArefBase;

/// Generate the code for registering passes.
#define GEN_PASS_REGISTRATION
#include "mlir/Pass/Pass.h"

std::unique_ptr<Pass> createNVWSLowerWarpGroup();
std::unique_ptr<Pass> createNVWSLowerAref();

} // namespace nvws
} // namespace triton
} // namespace mlir

#endif // DIALECT_NVWS_TRANSFORMS_PASSES_H_INC