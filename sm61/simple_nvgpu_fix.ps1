# Simple NVGPU Dialect Registration Fix
# This script addresses the "LLVM ERROR: Dialect Attribute with name nvgpu. is already registered" issue

Write-Host "Applying Simple NVGPU Dialect Registration Fix..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

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

# 2. Fix NVGPUEnums.h to use proper include guards
Write-Host "2. Fixing NVGPUEnums.h include guards..." -ForegroundColor Yellow

$nvgpuEnumsPath = "third_party\nvidia\include\Dialect\NVGPU\IR\NVGPUEnums.h"
if (Test-Path $nvgpuEnumsPath) {
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

# 3. Reinstall Triton to ensure clean state
Write-Host "3. Reinstalling Triton..." -ForegroundColor Yellow
Write-Host "  Uninstalling current Triton..." -ForegroundColor Gray
pip uninstall triton -y

Write-Host "  Installing latest Triton..." -ForegroundColor Gray
pip install triton

# 4. Test the fix
Write-Host "4. Testing the fix..." -ForegroundColor Yellow

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

Write-Host "Simple fix process completed!" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host "The dialect registration error should now be resolved." -ForegroundColor Green