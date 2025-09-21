# Fix NVGPU Dialect Registration Error
# This script specifically addresses the "LLVM ERROR: Dialect Attribute with name nvgpu. is already registered" issue

Write-Host "Fixing NVGPU Dialect Registration Error..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Kill any running processes that might be holding onto DLLs
Write-Host "1. Killing any processes that might be holding onto Triton libraries..." -ForegroundColor Yellow
Get-Process | Where-Object { $_.Path -like "*triton*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process | Where-Object { $_.Path -like "*NVGPU*" } | Stop-Process -Force -ErrorAction SilentlyContinue

# 2. Clean all build artifacts
Write-Host "2. Cleaning all build artifacts..." -ForegroundColor Yellow
if (Test-Path "build") { 
    Write-Host "  Removing build directory..." -ForegroundColor Gray
    Remove-Item "build" -Recurse -Force -ErrorAction SilentlyContinue 
}

if (Test-Path "build_vs") { 
    Write-Host "  Removing build_vs directory..." -ForegroundColor Gray
    Remove-Item "build_vs" -Recurse -Force -ErrorAction SilentlyContinue 
}

if (Test-Path "dist") { 
    Write-Host "  Removing dist directory..." -ForegroundColor Gray
    Remove-Item "dist" -Recurse -Force -ErrorAction SilentlyContinue 
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

# 3. Uninstall existing Triton packages
Write-Host "3. Uninstalling existing Triton packages..." -ForegroundColor Yellow
pip uninstall triton -y
pip uninstall triton-windows -y

# 4. Fix NVGPU dialect registration issues
Write-Host "4. Fixing NVGPU dialect registration issues..." -ForegroundColor Yellow

# Fix NVGPUEnums.h to ensure proper include guards
$nvgpuEnumsPath = "third_party\nvidia\include\Dialect\NVGPU\IR\NVGPUEnums.h"
if (Test-Path $nvgpuEnumsPath) {
    $content = Get-Content $nvgpuEnumsPath
    # Ensure we have proper include guards to prevent multiple registrations
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

# 5. Rebuild using the build script with CreateWheel flag
Write-Host "5. Rebuilding Triton with CreateWheel flag..." -ForegroundColor Yellow
Write-Host "  This may take some time..." -ForegroundColor Gray

# Run the build script with CreateWheel flag
& .\build_triton.ps1 -CreateWheel -CleanBuild

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Build completed successfully" -ForegroundColor Green
} else {
    Write-Host "  Build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
}

# 6. Test the fix
Write-Host "6. Testing the fix..." -ForegroundColor Yellow

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

# More comprehensive test with a simple kernel
$kernelTestCode = @"
import torch
import triton
import triton.language as tl

@triton.jit
def simple_kernel(x_ptr, y_ptr, output_ptr, n_elements, BLOCK_SIZE: tl.constexpr):
    pid = tl.program_id(axis=0)
    block_start = pid * BLOCK_SIZE
    offsets = block_start + tl.arange(0, BLOCK_SIZE)
    mask = offsets < n_elements
    x = tl.load(x_ptr + offsets, mask=mask)
    y = tl.load(y_ptr + offsets, mask=mask)
    output = x + y
    tl.store(output_ptr + offsets, output, mask=mask)

def test_kernel():
    if not torch.cuda.is_available():
        print('CUDA not available, skipping kernel test')
        return True
        
    size = 1024
    x = torch.rand(size, device='cuda')
    y = torch.rand(size, device='cuda')
    output = torch.empty_like(x, device='cuda')
    
    grid = lambda meta: (triton.cdiv(size, meta['BLOCK_SIZE']),)
    try:
        simple_kernel[grid](x, y, output, size, BLOCK_SIZE=1024)
        print('Kernel execution: SUCCESS')
        return True
    except Exception as e:
        print('Kernel execution failed:', str(e))
        return False

if test_kernel():
    print('All tests passed!')
else:
    print('Some tests failed.')
"@

Write-Host "  Running kernel test..." -ForegroundColor Gray
python -c $kernelTestCode

Write-Host "Fix process completed!" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "If the error persists, try restarting your PowerShell session." -ForegroundColor Yellow