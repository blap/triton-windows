#include "triton/Analysis/Alias.h"

#include "mlir/Support/LLVM.h"
#include "triton/Dialect/TritonGPU/IR/Dialect.h"

namespace mlir {

AliasInfo AliasInfo::join(const AliasInfo &lhs, const AliasInfo &rhs) {
  if (lhs == rhs)
    return lhs;
  AliasInfo ret;
  for (auto value : lhs.allocs) {
    ret.insert(value);
  }
  for (auto value : rhs.allocs) {
    ret.insert(value);
  }
  return ret;
}

LogicalResult SharedMemoryAliasAnalysis::visitOperation(
    Operation *op, ArrayRef<const dataflow::Lattice<AliasInfo> *> operands,
    ArrayRef<dataflow::Lattice<AliasInfo> *> results) {
  AliasInfo aliasInfo;
  bool pessimistic = true;
  auto result = op->getResult(0);
  // skip ops that return memdesc in a different memory space.
  if (auto memdescTy = dyn_cast<triton::gpu::MemDescType>(result.getType())) {
    if (!isa_and_nonnull<triton::gpu::SharedMemorySpaceAttr>(
            memdescTy.getMemorySpace()))
      return success();
  }

  // Only LocalAllocOp creates a new buffer.
  if (isa<triton::gpu::LocalAllocOp>(op)) {
    aliasInfo.insert(result);
    pessimistic = false;
  } else if (op->hasTrait<OpTrait::MemDescViewTrait>()) {
    aliasInfo = AliasInfo(operands[0]->getValue());
    pessimistic = false;
  } else {
    assert(!isa<triton::gpu::MemDescType>(result.getType()) &&
           "unknown operation creating memory descriptor");
  }

  if (pessimistic) {
    setAllToEntryStates(results);
    return success();
  }
  // Join all lattice elements
  for (auto *result : results)
    propagateIfChanged(result, result->join(aliasInfo));

  return success();
}

void SharedMemoryAliasAnalysis::visitNonControlFlowArguments(
    Operation *op, const RegionSuccessor &successor,
    ArrayRef<dataflow::Lattice<AliasInfo> *> argLattices, unsigned firstIndex) {
  auto wsOp = dyn_cast<triton::gpu::WarpSpecializePartitionsOp>(op);
  if (!wsOp) {
    setAllToEntryStates(argLattices.take_front(firstIndex));
    setAllToEntryStates(argLattices.drop_front(
        firstIndex + successor.getSuccessorInputs().size()));
    return;
  }

  // Propagate aliases from the parent operation's operands to the block
  // arguments.
  assert(!successor.isParent());
  ProgramPoint *point = getProgramPointAfter(wsOp);

  for (auto [capture, argLattice] :
       llvm::zip(wsOp.getParentOp().getExplicitCaptures(), argLattices)) {
    propagateIfChanged(
        argLattice,
        argLattice->join(getLatticeElementFor(point, capture)->getValue()));
  }
}

AliasResult SharedMemoryAliasAnalysis::alias(Value lhs, Value rhs) {
  // Get the lattice elements for both values
  dataflow::Lattice<AliasInfo> *lhsLattice = getLatticeElement(lhs);
  dataflow::Lattice<AliasInfo> *rhsLattice = getLatticeElement(rhs);
  
  // If we don't have lattice information for either value, conservatively assume they may alias
  if (!lhsLattice || !rhsLattice) {
    return AliasResult::MayAlias;
  }
  
  // Get the alias information from the lattice elements
  const AliasInfo &lhsInfo = lhsLattice->getValue();
  const AliasInfo &rhsInfo = rhsLattice->getValue();
  
  // If either value has no allocs (pessimistic state), conservatively assume they may alias
  if (lhsInfo.getAllocs().empty() || rhsInfo.getAllocs().empty()) {
    return AliasResult::MayAlias;
  }
  
  // Check if they share any common allocations
  for (const auto &lhsAlloc : lhsInfo.getAllocs()) {
    for (const auto &rhsAlloc : rhsInfo.getAllocs()) {
      if (lhsAlloc == rhsAlloc) {
        return AliasResult::MustAlias;
      }
    }
  }
  
  // If no common allocations, they don't alias
  return AliasResult::NoAlias;
}

ModRefResult SharedMemoryAliasAnalysis::getModRef(Operation *op,
                                                  Value location) {
  // For now, we conservatively assume that any operation that has a MemDescViewTrait
  // might modify or reference the location
  if (op->hasTrait<OpTrait::MemDescViewTrait>()) {
    return ModRefResult::getModAndRef();
  }
  
  // LocalAllocOp creates a new buffer, so it doesn't reference existing locations
  // but it might modify the location if it's being assigned to
  if (isa<triton::gpu::LocalAllocOp>(op)) {
    return ModRefResult::getMod();
  }
  
  // For other operations, conservatively assume they might modify and reference
  return ModRefResult::getModAndRef();
}

} // namespace mlir
