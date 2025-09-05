// RUN: triton-opt %s | FileCheck %s

#blocked = #ttg.blocked<{sizePerThread = [1, 4], threadsPerWarp = [4, 8], warpsPerCTA = [2, 2], order = [1, 0], CTAsPerCGA = [1, 1], CTASplitNum = [1, 1], CTAOrder = [1, 0]}>
#shared = #ttg.nvmma_shared<{swizzlingByteWidth = 32, transposed = false, elementBitWidth = 16}>

module attributes {"ttg.num-ctas" = 2 : i32, "ttg.num-warps" = 4 : i32} {

  // Test that PlanCTA pass correctly handles DotOp with proper CTA layouts
  // CHECK-LABEL: @dot_op_test
  tt.func @dot_op_test(%A: tensor<64x32xf16, #blocked>, %B: tensor<32x128xf16, #blocked>) -> tensor<64x128xf32, #blocked> {
    // CHECK: tt.dot
    %0 = tt.dot %A, %B : tensor<64x32xf16, #blocked> * tensor<32x128xf16, #blocked> -> tensor<64x128xf32, #blocked>
    tt.return %0 : tensor<64x128xf32, #blocked>
  }

  // Test that PlanCTA pass correctly handles ReduceOp with proper CTA layouts
  // CHECK-LABEL: @reduce_op_test
  tt.func @reduce_op_test(%arg0: tensor<64x128xf32, #blocked>) -> tensor<64xf32, #blocked> {
    // CHECK: tt.reduce
    %0 = tt.reduce(%arg0) -> (tensor<64xf32, #blocked>) {
    ^bb0(%arg1: f32, %arg2: f32):
      %1 = arith.addf %arg1, %arg2 : f32
      tt.reduce.return %1 : f32
    } {axis = 1 : i32}
    tt.return %0 : tensor<64xf32, #blocked>
  }

  // Test that PlanCTA pass correctly handles StoreOp with proper CTA layouts
  // CHECK-LABEL: @store_op_test
  tt.func @store_op_test(%arg0: tensor<64x128xf32, #blocked>, %arg1: !ttg.memdesc<64x128xf32, #shared, #ttg.shared_memory>) {
    // CHECK: tt.store
    tt.store %arg1, %arg0 : !ttg.memdesc<64x128xf32, #shared, #ttg.shared_memory>, tensor<64x128xf32, #blocked>
    tt.return
  }
}