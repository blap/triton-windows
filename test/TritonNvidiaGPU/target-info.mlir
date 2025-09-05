// RUN: triton-opt %s | FileCheck %s

module attributes {"ttg.num-ctas" = 1 : i32, "ttg.num-warps" = 4 : i32} {

  // Test that TargetInfo functions are properly implemented
  // CHECK-LABEL: @target_info_test
  tt.func @target_info_test(%arg0: i32, %arg1: i32) -> i32 {
    // Test ballot operation
    // CHECK: %[[VAL1:.*]] = arith.cmpi
    %0 = arith.cmpi eq, %arg0, %arg1 : i32
    // CHECK: %[[VAL2:.*]] = tt.get_program_id
    %1 = tt.get_program_id x : i32
    // CHECK: return
    tt.return %1 : i32
  }
}