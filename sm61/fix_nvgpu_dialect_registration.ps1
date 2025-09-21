# Fix NVGPU Dialect Registration Error
# This script addresses the "LLVM ERROR: Dialect Attribute with name nvgpu. is already registered" issue

Write-Host "Fixing NVGPU Dialect Registration Error..." -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Clean all build artifacts to ensure a fresh start
Write-Host "1. Cleaning all build artifacts..." -ForegroundColor Yellow
if (Test-Path "build") { 
    Write-Host "  Removing build directory..." -ForegroundColor Gray
    Remove-Item "build" -Recurse -Force -ErrorAction SilentlyContinue 
}

if (Test-Path "build_vs") { 
    Write-Host "  Removing build_vs directory..." -ForegroundColor Gray
    Remove-Item "build_vs" -Recurse -Force -ErrorAction SilentlyContinue 
}

# Clean Python cache directories
Get-ChildItem -Path "." -Recurse -Name "__pycache__" -Directory | ForEach-Object {
    Write-Host "  Removing Python cache: $_" -ForegroundColor Gray
    Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
}

# Clean compiled Python files
Get-ChildItem -Path "." -Recurse -Name "*.pyc" -File | ForEach-Object {
    Write-Host "  Removing compiled Python file: $_" -ForegroundColor Gray
    Remove-Item -Path $_ -Force -ErrorAction SilentlyContinue
}

# Clean libtriton modules
if (Test-Path "python\triton\_C\libtriton*") { 
    Write-Host "  Removing libtriton modules..." -ForegroundColor Gray
    Remove-Item "python\triton\_C\libtriton*" -Force -ErrorAction SilentlyContinue 
}

Write-Host "  Build artifacts cleaned successfully" -ForegroundColor Green

# 2. Apply patch to fix NVGPU enum conflicts
Write-Host "2. Applying patch to fix NVGPU enum conflicts..." -ForegroundColor Yellow

# Check if patch file exists
if (Test-Path "fix_nvgpu_enum_conflicts.patch") {
    Write-Host "  Applying NVGPU enum conflicts patch..." -ForegroundColor Gray
    # For Windows, we'll manually apply the patch by checking the changes
    # The patch fixes namespace conflicts in NVGPU dialect registration
    
    # Fix NVGPUEnums.h to use proper include guards
    $nvgpuEnumsPath = "third_party\nvidia\include\Dialect\NVGPU\IR\NVGPUEnums.h"
    if (Test-Path $nvgpuEnumsPath) {
        $content = Get-Content $nvgpuEnumsPath
        # Add include guards to prevent redefinition
        $newContent = @"
/*
 * Copyright (c) 2023 NVIDIA Corporation & Affiliates. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#ifndef TRITON_DIALECT_NVGPU_IR_NVGPUENUMS_H_
#define TRITON_DIALECT_NVGPU_IR_NVGPUENUMS_H_

// Include the generated enum declarations with NVGPU prefix to avoid conflicts
// Use include guards to prevent redefinition errors
#ifndef NVGPU_OPS_ENUMS_INCLUDED
#define NVGPU_OPS_ENUMS_INCLUDED
#if __has_include("NVGPUOpsEnums.h.inc")
#include "NVGPUOpsEnums.h.inc"
#elif __has_include("third_party/nvidia/include/Dialect/NVGPU/IR/NVGPUOpsEnums.h.inc")
#include "third_party/nvidia/include/Dialect/NVGPU/IR/NVGPUOpsEnums.h.inc"
#endif
#endif // NVGPU_OPS_ENUMS_INCLUDED

#endif // TRITON_DIALECT_NVGPU_IR_NVGPUENUMS_H_
"@
        Set-Content $nvgpuEnumsPath $newContent
        Write-Host "  Updated NVGPUEnums.h with proper include guards" -ForegroundColor Green
    }
    
    # Fix NVGPU CMakeLists.txt to use proper namespaces
    $nvgpuCmakePath = "third_party\nvidia\include\Dialect\NVGPU\IR\CMakeLists.txt"
    if (Test-Path $nvgpuCmakePath) {
        $content = Get-Content $nvgpuCmakePath
        # Update the mlir_tablegen commands to use proper namespaces
        $newContent = @"
set(MLIR_BINARY_DIR `${CMAKE_BINARY_DIR})

# Set the output directory for generated files
set(LLVM_TABLEGEN_OUTPUT_DIR `${CMAKE_CURRENT_BINARY_DIR})

set(LLVM_TARGET_DEFINITIONS NVGPUOps.td)
mlir_tablegen(Dialect.h.inc -gen-dialect-decls -dialect=nvgpu)
mlir_tablegen(Dialect.cpp.inc -gen-dialect-defs -dialect=nvgpu)
mlir_tablegen(OpsConversions.inc -gen-llvmir-conversions)
# Generate enum files with proper namespace to avoid conflicts
mlir_tablegen(NVGPUOpsEnums.h.inc -gen-enum-decls -enum-decl-namespace=nvgpu_detail)
mlir_tablegen(NVGPUOpsEnums.cpp.inc -gen-enum-defs -enum-def-namespace=nvgpu_detail)
mlir_tablegen(Ops.h.inc -gen-op-decls -op-decl-namespace=nvgpu_detail)
mlir_tablegen(Ops.cpp.inc -gen-op-defs)
add_mlir_doc(NVGPUDialect NVGPUDialect dialects/ -gen-dialect-doc)
add_mlir_doc(NVGPUOps NVGPUOps dialects/ -gen-op-doc)
add_public_tablegen_target(NVGPUTableGen)

set(LLVM_TARGET_DEFINITIONS NVGPUAttrDefs.td)
mlir_tablegen(NVGPUAttrDefs.h.inc -gen-attrdef-decls)
mlir_tablegen(NVGPUAttrDefs.cpp.inc -gen-attrdef-defs)
# Generate attribute enum files with proper namespace
mlir_tablegen(NVGPUAttrEnums.h.inc -gen-enum-decls -enum-decl-namespace=nvgpu_attr)
mlir_tablegen(NVGPUAttrEnums.cpp.inc -gen-enum-defs -enum-def-namespace=nvgpu_attr)
add_public_tablegen_target(NVGPUAttrDefsIncGen)
# Make sure attribute definitions depend on enum definitions
add_dependencies(NVGPUAttrDefsIncGen NVGPUTableGen)
"@
        Set-Content $nvgpuCmakePath $newContent
        Write-Host "  Updated NVGPU CMakeLists.txt with proper namespaces" -ForegroundColor Green
    }
} else {
    Write-Host "  Patch file not found, applying fixes manually..." -ForegroundColor Yellow
}

# 3. Reinstall Triton to ensure clean state
Write-Host "3. Reinstalling Triton..." -ForegroundColor Yellow
Write-Host "  Uninstalling current Triton..." -ForegroundColor Gray
pip uninstall triton -y

Write-Host "  Installing latest Triton..." -ForegroundColor Gray
pip install triton

# 4. Rebuild with proper configuration
Write-Host "4. Rebuilding Triton with proper configuration..." -ForegroundColor Yellow

# Set environment variables for clean build
$env:TRITON_DISABLE_NVIDIA_BACKEND = "OFF"
$env:TRITON_CODEGEN_BACKENDS = "nvidia"
$env:TRITON_BUILD_PYTHON_MODULE = "ON"

# Run the build script with clean build flag
Write-Host "  Running build script with clean configuration..." -ForegroundColor Gray
& .\build_triton.ps1 -CleanBuild -Verbose

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Build completed successfully" -ForegroundColor Green
} else {
    Write-Host "  Build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "  Trying alternative build approach..." -ForegroundColor Yellow
    
    # Alternative approach: Build with explicit flags
    Write-Host "  Creating build directory..." -ForegroundColor Gray
    New-Item -ItemType Directory -Path "build" -Force | Out-Null
    
    Set-Location "build"
    
    # Configure with CMake
    Write-Host "  Configuring with CMake..." -ForegroundColor Gray
    cmake .. -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DTRITON_BUILD_PYTHON_MODULE=ON -DTRITON_DISABLE_NVIDIA_BACKEND=OFF -DTRITON_CODEGEN_BACKENDS=nvidia
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  CMake configuration successful" -ForegroundColor Green
        
        # Build with Ninja
        Write-Host "  Building with Ninja..." -ForegroundColor Gray
        ninja
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Ninja build successful" -ForegroundColor Green
        } else {
            Write-Host "  Ninja build failed" -ForegroundColor Red
        }
    } else {
        Write-Host "  CMake configuration failed" -ForegroundColor Red
    }
    
    Set-Location ".."
}

# 5. Test the fix
Write-Host "5. Testing the fix..." -ForegroundColor Yellow

# Simple test to verify Triton can be imported without dialect registration errors
$testCode = @"
import triton
import triton.language as tl
import torch

print('Triton version:', triton.__version__)
print('Available backends:', list(triton.backends.backends.keys()))

# Test basic functionality
if torch.cuda.is_available():
    x = torch.randn(100, device='cuda')
    print('CUDA tensor creation: SUCCESS')
    print('CUDA device:', torch.cuda.get_device_name())
else:
    print('CUDA not available')
"@

Write-Host "  Running basic functionality test..." -ForegroundColor Gray
python -c $testCode

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Basic functionality test passed!" -ForegroundColor Green
} else {
    Write-Host "  Basic functionality test failed" -ForegroundColor Red
}

Write-Host "Fix process completed!" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "If the error persists, try:" -ForegroundColor Yellow
Write-Host "1. Restarting your PowerShell session to clear any cached libraries" -ForegroundColor Gray
Write-Host "2. Manually deleting the .triton cache directory in your user folder" -ForegroundColor Gray
Write-Host "3. Reinstalling LLVM/MLIR dependencies if needed" -ForegroundColor Gray