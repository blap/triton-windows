# NVGPU Dialect Enum Resolution

## Overview
This directory contains the NVGPU dialect implementation with resolved enum conflicts. The enum naming conflicts between the main Triton dialect and the NVGPU dialect have been resolved by renaming the NVGPU enums to use unique prefixes.

## Changes Made

### Enum Renaming
The following enums were renamed to avoid conflicts:
- `MemSemantic` → `NVGPUMemSemantic`
- `MemSyncScope` → `NVGPUMemSyncScope`

### Files Modified
1. **[NVGPUOps.td](file:///c%3A/Users/Admin/Documents/GitHub/triton-windows/third_party/nvidia/include/Dialect/NVGPU/IR/NVGPUOps.td)** - Contains the TableGen definitions for NVGPU operations and renamed enums
2. **[Dialect.h](file:///c%3A/Users/Admin/Documents/GitHub/triton-windows/third_party/nvidia/include/Dialect/NVGPU/IR/Dialect.h)** - Updated to include NVGPUEnums.h for proper enum declaration ordering
3. **[NVGPUEnums.h](file:///c%3A/Users/Admin/Documents/GitHub/triton-windows/third_party/nvidia/include/Dialect/NVGPU/IR/NVGPUEnums.h)** - New header file to explicitly include enum declarations

## Why This Was Necessary
When both the main Triton dialect and the NVGPU dialect were included in the same compilation unit, they both defined enums with the same names (`MemSemantic` and `MemSyncScope`). This caused template specialization conflicts during compilation, particularly with MSVC on Windows.

## Solution Approach
We used a namespace isolation approach by:
1. Renaming the NVGPU dialect enums to use unique prefixes (`NVGPU`)
2. Ensuring proper header inclusion order
3. Maintaining compatibility with the main Triton dialect

## Verification
The solution has been verified to work correctly:
- NVGPU dialect now uses `NVGPUMemSemantic` and `NVGPUMemSyncScope`
- Main Triton dialect continues to use `MemSemantic` and `MemSyncScope`
- Both dialects can coexist without conflicts
- LoadAcquireOp correctly references the new enum attributes

## Related Documentation
- [NVGPU_ENUM_CONFLICT_RESOLUTION_CLEAN.md](file:///c%3A/Users/Admin/Documents/GitHub/triton-windows/NVGPU_ENUM_CONFLICT_RESOLUTION_CLEAN.md) - Detailed technical documentation
- [test_nvgpu_enum_resolution.py](file:///c%3A/Users/Admin/Documents/GitHub/triton-windows/test_nvgpu_enum_resolution.py) - Verification script