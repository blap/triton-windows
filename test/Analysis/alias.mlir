// RUN: triton-opt %s | FileCheck %s

#blocked = #ttg.blocked<{sizePerThread = [1, 4], threadsPerWarp = [4, 8], warpsPerCTA = [2, 2], order = [1, 0], CTAsPerCGA = [1, 1], CTASplitNum = [1, 1], CTAOrder = [1, 0]}>
#shared = #ttg.nvmma_shared<{swizzlingByteWidth = 32, transposed = false, elementBitWidth = 16}>

module attributes {"ttg.num-ctas" = 1 : i32, "ttg.num-warps" = 4 : i32} {

  // Test that Alias analysis correctly identifies aliasing relationships
  // CHECK-LABEL: @alias_test
  tt.func @alias_test(%arg0: !ttg.memdesc<64x128xf32, #shared, #ttg.shared_memory, mutable>) -> (!ttg.memdesc<64x128xf32, #shared, #ttg.shared_memory, mutable>, !ttg.memdesc<64x128xf32, #shared, #ttg.shared_memory, mutable>) {
    // CHECK: %[[VAL1:.*]] = tt.load
    %0 = tt.load %arg0 : !ttg.memdesc<64x128xf32, #shared, #ttg.shared_memory, mutable> -> tensor<64x128xf32, #blocked>
    
    // CHECK: %[[VAL2:.*]] = ttg.local_alloc
    %1 = ttg.local_alloc %0 : tensor<64x128xf32, #blocked> -> !ttg.memdesc<64x128xf32, #shared, #ttg.shared_memory, mutable>
    
    // CHECK: tt.store
    tt.store %1, %0 : !ttg.memdesc<64x128xf32, #shared, #ttg.shared_memory, mutable>, tensor<64x128xf32, #blocked>
    
    // CHECK: return %[[VAL1]], %[[VAL2]]
    tt.return %arg0, %1 : !ttg.memdesc<64x128xf32, #shared, #ttg.shared_memory, mutable>, !ttg.memdesc<64x128xf32, #shared, #ttg.shared_memory, mutable>
  }
}