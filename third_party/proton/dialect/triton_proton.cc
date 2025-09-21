#include "Dialect/Proton/IR/Dialect.h"
#include "mlir/Pass/PassManager.h"
#include "passes.h"
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/stl_bind.h>

namespace py = pybind11;

void init_triton_proton(py::module &&m) {
  auto passes = m.def_submodule("passes");

  // load dialects
  m.def("load_dialects", [](mlir::MLIRContext &context) {
    mlir::DialectRegistry registry;
    registry.insert<mlir::triton::proton::ProtonDialect>();
    context.appendDialectRegistry(registry);
    // DO NOT call context.loadAllAvailableDialects() as it would try to load
    // NVGPU dialect again, which is already registered in registerTritonDialects
    // and would cause "LLVM ERROR: Dialect Attribute with name nvgpu. is already registered"
    // context.loadAllAvailableDialects();
  });
}