# Triton Windows Build TODO List

## Main Objectives
- [ ] Successfully compile wheel for Windows with NVIDIA support only
- [ ] Successfully compile wheel for Windows with CPU support only

## Current Issues to Resolve

### NVIDIA Support Issues
- [ ] Fix unresolved external symbol errors in TritonNVIDIA.dll linking
- [ ] Resolve namespace mismatches in populateClampFOpToLLVMPattern function
- [ ] Fix TargetInfo class implementation issues
- [ ] Ensure all NVIDIA-specific headers are properly included
- [ ] Verify MLIRUBToLLVM library linking

### CPU Support Issues
- [ ] Identify and resolve CPU-specific compilation issues
- [ ] Ensure core Triton functionality works without NVIDIA dependencies

## Build Process Improvements
- [ ] Clean up build scripts (build.ps1)
- [ ] Ensure proper error handling and logging
- [ ] Add verification steps for successful builds
- [ ] Implement build timeout mechanism

## Code Cleanup Tasks
- [x] Remove any temporary/unnecessary code additions
- [x] Fix syntax errors introduced during development
- [x] Ensure proper code formatting and comments
- [x] Verify all file modifications are necessary and correct
- [x] Remove unnecessary build artifacts and directories
- [x] Confirm .inc files are necessary for MLIR compilation

## Testing and Verification
- [ ] Test NVIDIA backend functionality in final wheel
- [ ] Verify wheel integrity and contents
- [ ] Test installation process
- [ ] Confirm no regressions in existing functionality

## Documentation
- [ ] Document all changes made clearly
- [ ] Update build instructions if needed
- [ ] Note any platform-specific considerations

## Priority Tasks (Do First)
1. [x] Fix ElementwiseOpToLLVM.cpp syntax errors
2. [ ] Resolve populateClampFOpToLLVMPattern linking issues
3. [x] Clean up unnecessary code additions
4. [ ] Successfully build wheel with NVIDIA support
5. [x] Remove unnecessary build artifacts and directories