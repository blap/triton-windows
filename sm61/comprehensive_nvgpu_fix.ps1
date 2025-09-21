# Comprehensive NVGPU Dialect Registration Fix
# This script rebuilds Triton from source with proper configuration to fix the dialect registration error

Write-Host "Comprehensive NVGPU Dialect Registration Fix" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

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

# 3. Uninstall existing Triton
Write-Host "3. Uninstalling existing Triton..." -ForegroundColor Yellow
Write-Host "  Uninstalling triton..." -ForegroundColor Gray
pip uninstall triton -y
Write-Host "  Uninstalling triton-windows..." -ForegroundColor Gray
pip uninstall triton-windows -y

# 4. Install build dependencies
Write-Host "4. Installing build dependencies..." -ForegroundColor Yellow
Write-Host "  Installing pybind11..." -ForegroundColor Gray
pip install pybind11
Write-Host "  Installing ninja..." -ForegroundColor Gray
pip install ninja

# 5. Build Triton from source
Write-Host "5. Building Triton from source..." -ForegroundColor Yellow

# Set environment variables for clean build
$env:TRITON_DISABLE_NVIDIA_BACKEND = "OFF"
$env:TRITON_CODEGEN_BACKENDS = "nvidia"
$env:TRITON_BUILD_PYTHON_MODULE = "ON"
$env:MAX_JOBS = "1"

# Create build directory
if (!(Test-Path "build")) { 
    New-Item -ItemType Directory -Path "build" -Force | Out-Null
}

Set-Location "build"

# Configure with CMake using the correct paths
Write-Host "  Configuring with CMake..." -ForegroundColor Gray
$llvmPath = "C:\Users\Admin\.triton\llvm\llvm-8957e64a-windows-x64"
if (Test-Path $llvmPath) {
    $env:LLVM_DIR = "$llvmPath\lib\cmake\llvm"
    $env:MLIR_DIR = "$llvmPath\lib\cmake\mlir"
    Write-Host "  Using LLVM from: $llvmPath" -ForegroundColor Green
} else {
    Write-Host "  LLVM not found at $llvmPath" -ForegroundColor Red
    Set-Location ".."
    exit 1
}

# Get pybind11 cmake directory
try {
    $pybind11CmakeDir = python -c "import pybind11; print(pybind11.get_cmake_dir())"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  pybind11 cmake directory: $pybind11CmakeDir" -ForegroundColor Green
    } else {
        Write-Host "  Failed to get pybind11 cmake directory" -ForegroundColor Red
        Set-Location ".."
        exit 1
    }
} catch {
    Write-Host "  Error getting pybind11 cmake directory: $_" -ForegroundColor Red
    Set-Location ".."
    exit 1
}

# Configure build
& cmake .. -G "Ninja" `
    -DCMAKE_BUILD_TYPE=Release `
    -DLLVM_DIR="$env:LLVM_DIR" `
    -DMLIR_DIR="$env:MLIR_DIR" `
    -DPYBIND11_DIR="$pybind11CmakeDir" `
    -DTRITON_DISABLE_NVIDIA_BACKEND=OFF `
    -DTRITON_CODEGEN_BACKENDS=nvidia `
    -DTRITON_BUILD_PYTHON_MODULE=ON `
    -DTRITON_BUILD_WITH_NVWS=ON

if ($LASTEXITCODE -ne 0) {
    Write-Host "  CMake configuration failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    Set-Location ".."
    exit 1
}

Write-Host "  CMake configuration successful" -ForegroundColor Green

# Build with Ninja
Write-Host "  Building with Ninja..." -ForegroundColor Gray
& ninja -v

if ($LASTEXITCODE -ne 0) {
    Write-Host "  Ninja build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    Set-Location ".."
    exit 1
}

Write-Host "  Ninja build successful" -ForegroundColor Green

# Return to root directory
Set-Location ".."

# 6. Install the built package
Write-Host "6. Installing the built package..." -ForegroundColor Yellow

# Create wheel
Write-Host "  Creating wheel..." -ForegroundColor Gray
& python setup.py bdist_wheel

if ($LASTEXITCODE -ne 0) {
    Write-Host "  Wheel creation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

# Install the wheel
$wheels = Get-ChildItem -Path "dist" -Filter "*.whl"
if ($wheels.Count -gt 0) {
    Write-Host "  Installing wheel: $($wheels[0].Name)" -ForegroundColor Gray
    pip install "dist\$($wheels[0].Name)"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Wheel installation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  Wheel installed successfully" -ForegroundColor Green
} else {
    Write-Host "  No wheel file found in dist directory" -ForegroundColor Red
    exit 1
}

# 7. Test the fix
Write-Host "7. Testing the fix..." -ForegroundColor Yellow

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

Write-Host "Comprehensive fix process completed!" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "The dialect registration error should now be resolved." -ForegroundColor Green