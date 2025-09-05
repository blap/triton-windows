//===- PrintLoadStoreMemSpaces.cpp - Print Load/Store Memory Spaces -------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This pass prints the memory address spaces of load and store operations.
//
//===----------------------------------------------------------------------===//

#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include <map>
#include <string>

using namespace llvm;

#define DEBUG_TYPE "print-load-store-mem-spaces"

namespace {

struct LoadStoreMemSpace : public PassInfoMixin<LoadStoreMemSpace> {
  PreservedAnalyses run(Module &module, ModuleAnalysisManager &) {
    bool modified = false;
    for (Function &F : module) {
      if (F.isDeclaration())
        continue;
      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          std::string loadOrStore = LoadOrStoreMap(I);
          if (loadOrStore != "") {
            errs() << "MemSpace: " << loadOrStore << "\n";
            modified = true;
          }
        }
      }
    }
    return (modified ? llvm::PreservedAnalyses::none()
                     : llvm::PreservedAnalyses::all());
  }

private:
  static std::string LoadOrStoreMap(Instruction &I) {
    if (isa<LoadInst>(I)) {
      return "LOAD";
    } else if (isa<StoreInst>(I)) {
      return "STORE";
    }
    return "";
  }
};

} // end anonymous namespace

static PassPluginLibraryInfo getPassPluginInfo() {
  const auto Callback = [](PassBuilder &PB) {
    PB.registerPipelineParsingCallback(
        [](StringRef Name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
          if (Name == "print-mem-space") {
            MPM.addPass(LoadStoreMemSpace());
            return true;
          }
          return false;
        });
  };

  return {LLVM_PLUGIN_API_VERSION, "print-mem-space", LLVM_VERSION_STRING,
          Callback};
};

// Use LLVM_ATTRIBUTE_WEAK to match the LLVM header declaration
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return getPassPluginInfo();
}