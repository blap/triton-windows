# Triton Windows Build Script
# Updated script for building Triton with NVIDIA GPU support on Windows
# Fully automated compilation and wheel creation

param(
    [switch]$DisableNvidia,
    [string]$PythonPath = "",
    [int]$BuildTimeout = 3600,  # 1 hour default
    [switch]$Verbose,
    [switch]$CleanBuild,
    [switch]$SkipTests,
    [switch]$ForceRebuild,
    [switch]$InstallDependencies,
    [switch]$CreateWheel  # New parameter to create wheel distribution
)

# ----------------------------------------
# Utility Functions
# ----------------------------------------

function Write-Log {
    param([string]$Message, [string]$Color = "Gray")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Write-ErrorAndExit {
    param([string]$Message)
    
    Write-Log "ERROR: $Message" -Color "Red"
    exit 1
}

function Find-Python {
    param([string]$PythonPath)
    
    Write-Log "Finding Python installation..." -Color "Cyan"
    
    # Use provided path if valid
    if ($PythonPath -and (Test-Path $PythonPath)) {
        return $PythonPath
    }
    
    # Search common Python locations
    $paths = @(
        "C:\Program Files\Python312\python.exe",
        "C:\Program Files\Python311\python.exe",
        "C:\Program Files\Python310\python.exe"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) { 
            Write-Log "Found Python: $path" -Color "Green"
            return $path 
        }
    }
    
    # Try PATH
    try {
        $path = (Get-Command python -ErrorAction SilentlyContinue).Source
        if ($path -and (Test-Path $path)) { 
            Write-Log "Found Python in PATH: $path" -Color "Green"
            return $path 
        }
    } catch {}
    
    return $null
}

function Find-VisualStudio {
    Write-Log "Finding Visual Studio installation..." -Color "Cyan"
    
    # Try to find Visual Studio using vswhere
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        try {
            $vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
            if ($vsPath -and (Test-Path $vsPath)) {
                Write-Log "Found Visual Studio via vswhere: $vsPath" -Color "Green"
                return $vsPath
            }
        } catch {}
    }
    
    # Try common Visual Studio locations
    $paths = @(
        "C:\Program Files\Microsoft Visual Studio\2022\Community",
        "C:\Program Files\Microsoft Visual Studio\2022\Professional",
        "C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) { 
            Write-Log "Found Visual Studio: $path" -Color "Green"
            return $path
        }
    }
    return $null
}

function Setup-VSEnvironment {
    Write-Log "Setting up Visual Studio environment..." -Color "Cyan"
    
    # Find Visual Studio installation
    $vsPath = Find-VisualStudio
    if (-not $vsPath) {
        Write-Log "Visual Studio installation not found" -Color "Red"
        return $false
    }
    
    Write-Log "Found Visual Studio via vswhere: $vsPath" -Color "Green"
    
    # Run vcvars64.bat to set up environment
    $vcVarsPath = "$vsPath\VC\Auxiliary\Build\vcvars64.bat"
    if (-not (Test-Path $vcVarsPath)) {
        Write-Log "vcvars64.bat not found at $vcVarsPath" -Color "Red"
        return $false
    }
    
    Write-Log "Running vcvars64.bat to set up environment..." -Color "Gray"
    
    # Use cmd to run vcvars64.bat and capture the environment
    # Properly quote the path to handle spaces
    $envVars = cmd /c """$vcVarsPath"" && set" | Out-String
    
    # Parse and set environment variables
    $envVars -split "`r?`n" | ForEach-Object {
        if ($_ -match "^(\w+)=(.*)$") {
            $varName = $matches[1]
            $varValue = $matches[2]
            [System.Environment]::SetEnvironmentVariable($varName, $varValue, "Process")
        }
    }
    
    # Verify that INCLUDE path is set
    if ($env:INCLUDE) {
        Write-Log "INCLUDE path set to: $env:INCLUDE" -Color "Green"
    } else {
        Write-Log "INCLUDE path not set after vcvars64.bat" -Color "Red"
        return $false
    }
    
    # Explicitly add Visual Studio include paths for C++ standard library headers
    $vsIncludePaths = @(
        "$vsPath\VC\Tools\MSVC\14.44.35207\include",
        "$vsPath\VC\Tools\MSVC\14.44.35207\atlmfc\include",
        "$vsPath\VC\Auxiliary\VS\include",
        "C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt",
        "C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\um",
        "C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\shared",
        "C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\winrt",
        "C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\cppwinrt"
    )
    
    # Add these paths to the INCLUDE environment variable
    $currentInclude = $env:INCLUDE
    foreach ($path in $vsIncludePaths) {
        if (Test-Path $path) {
            if (-not $currentInclude.Contains($path)) {
                $currentInclude = "$path;$currentInclude"
            }
        }
    }
    $env:INCLUDE = $currentInclude
    
    Write-Log "Visual Studio environment variables set via vcvars" -Color "Green"
    return $true
}

function Find-CudaToolkit {
    Write-Log "Finding CUDA Toolkit..." -Color "Cyan"
    
    # Check common CUDA installation paths
    $cudaPaths = @(
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.9",
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8",
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.7"
    )
    
    foreach ($path in $cudaPaths) {
        if (Test-Path $path) { 
            Write-Log "Found CUDA Toolkit: $path" -Color "Green"
            return $path 
        }
    }
    
    # Check environment variables
    if ($env:CUDA_PATH) {
        Write-Log "Using CUDA from CUDA_PATH: $env:CUDA_PATH" -Color "Green"
        return $env:CUDA_PATH
    }
    
    Write-Log "Warning: CUDA Toolkit not found" -Color "Yellow"
    return $null
}

# New function to find LLVM/MLIR installation
function Find-LLVM {
    Write-Log "Finding LLVM/MLIR installation..." -Color "Cyan"
    
    # Check common LLVM installation paths
    $llvmPaths = @(
        "C:\Users\Admin\.triton\llvm\llvm-8957e64a-windows-x64",
        "C:\Program Files\LLVM",
        "C:\llvm"
    )
    
    foreach ($path in $llvmPaths) {
        if (Test-Path $path) { 
            Write-Log "Found LLVM: $path" -Color "Green"
            return $path 
        }
    }
    
    # Check environment variables
    if ($env:LLVM_DIR) {
        # Extract base path from LLVM_DIR
        $basePath = $env:LLVM_DIR -replace "\\lib\\cmake\\llvm$", ""
        if (Test-Path $basePath) {
            Write-Log "Using LLVM from LLVM_DIR: $basePath" -Color "Green"
            return $basePath
        }
    }
    
    if ($env:MLIR_DIR) {
        # Extract base path from MLIR_DIR
        $basePath = $env:MLIR_DIR -replace "\\lib\\cmake\\mlir$", ""
        if (Test-Path $basePath) {
            Write-Log "Using LLVM from MLIR_DIR: $basePath" -Color "Green"
            return $basePath
        }
    }
    
    Write-Log "Warning: LLVM/MLIR not found" -Color "Yellow"
    return $null
}

# New function to find pybind11
function Find-Pybind11 {
    Write-Log "Finding pybind11 installation..." -Color "Cyan"
    
    # Try to find pybind11 using Python
    try {
        $pybind11Path = & python -c "import pybind11; print(pybind11.get_cmake_dir())" 2>$null
        if ($pybind11Path -and (Test-Path $pybind11Path)) {
            Write-Log "Found pybind11: $pybind11Path" -Color "Green"
            return $pybind11Path
        }
    } catch {
        Write-Log "Could not find pybind11 via Python" -Color "Yellow"
    }
    
    # Try common installation paths
    $pybind11Paths = @(
        "C:\Users\Admin\AppData\Roaming\Python\Python312\site-packages\pybind11\share\cmake\pybind11",
        "C:\Program Files\Python312\Lib\site-packages\pybind11\share\cmake\pybind11"
    )
    
    foreach ($path in $pybind11Paths) {
        if (Test-Path $path) {
            Write-Log "Found pybind11: $path" -Color "Green"
            return $path
        }
    }
    
    Write-Log "Warning: pybind11 not found" -Color "Yellow"
    return $null
}

# New function to setup LLVM/MLIR environment
function Setup-LLVMEnvironment {
    param([string]$llvmPath)
    
    Write-Log "Setting up LLVM/MLIR environment..." -Color "Cyan"
    
    if ($llvmPath -and (Test-Path $llvmPath)) {
        # Set LLVM_DIR and MLIR_DIR environment variables
        $llvmCmakePath = "$llvmPath\lib\cmake\llvm"
        $mlirCmakePath = "$llvmPath\lib\cmake\mlir"
        
        if (Test-Path $llvmCmakePath) {
            $env:LLVM_DIR = $llvmCmakePath
            Write-Log "Set LLVM_DIR to: $llvmCmakePath" -Color "Green"
        } else {
            Write-Log "Warning: LLVM CMake directory not found at $llvmCmakePath" -Color "Yellow"
        }
        
        if (Test-Path $mlirCmakePath) {
            $env:MLIR_DIR = $mlirCmakePath
            Write-Log "Set MLIR_DIR to: $mlirCmakePath" -Color "Green"
        } else {
            Write-Log "Warning: MLIR CMake directory not found at $mlirCmakePath" -Color "Yellow"
        }
        
        # Add LLVM bin directory to PATH
        $llvmBinPath = "$llvmPath\bin"
        if (Test-Path $llvmBinPath) {
            $env:PATH = "$llvmBinPath;$env:PATH"
            Write-Log "Added LLVM bin to PATH: $llvmBinPath" -Color "Green"
        }
        
        # Verify essential components exist
        $essentialComponents = @(
            "$llvmPath\include\mlir",
            "$llvmCmakePath\LLVMConfig.cmake",
            "$mlirCmakePath\MLIRConfig.cmake"
        )
        
        $missingComponents = @()
        foreach ($component in $essentialComponents) {
            if (-not (Test-Path $component)) {
                $missingComponents += $component
            }
        }
        
        if ($missingComponents.Count -gt 0) {
            Write-Log "Warning: Missing essential LLVM/MLIR components:" -Color "Yellow"
            foreach ($component in $missingComponents) {
                Write-Log "  - $component" -Color "Yellow"
            }
            Write-Log "Build may fail due to missing dependencies." -Color "Yellow"
        } else {
            Write-Log "LLVM/MLIR environment verified successfully" -Color "Green"
        }
    } else {
        Write-Log "Warning: Cannot setup LLVM environment - path not valid" -Color "Yellow"
    }
}

# New function to install LLVM/MLIR dependencies
function Install-LLVMDependencies {
    Write-Log "Installing LLVM/MLIR dependencies..." -Color "Cyan"
    
    # Create the directory if it doesn't exist
    $llvmBasePath = "C:\Users\Admin\.triton\llvm"
    $llvmPath = "C:\Users\Admin\.triton\llvm\llvm-8957e64a-windows-x64"
    
    if (-not (Test-Path $llvmBasePath)) {
        New-Item -ItemType Directory -Path $llvmBasePath -Force | Out-Null
    }
    
    # For now, we'll just provide instructions since automatic installation is complex
    Write-Log "Manual installation required for LLVM/MLIR:" -Color "Yellow"
    Write-Log "1. Download LLVM/MLIR from https://github.com/llvm/llvm-project" -Color "Yellow"
    Write-Log "2. Build LLVM/MLIR with CMake:" -Color "Yellow"
    Write-Log "   mkdir build && cd build" -Color "Yellow"
    Write-Log "   cmake -G Ninja -DLLVM_ENABLE_PROJECTS=mlir -DCMAKE_BUILD_TYPE=Release .." -Color "Yellow"
    Write-Log "   ninja" -Color "Yellow"
    Write-Log "3. Install to $llvmPath" -Color "Yellow"
    Write-Log "Alternatively, set LLVM_DIR and MLIR_DIR environment variables to point to existing installations." -Color "Yellow"
    
    Write-Log "For now, continuing with build process (may fail if dependencies are missing)..." -Color "Yellow"
}

# New function to check and create missing header files
function Check-And-CreateMissingHeaders {
    Write-Log "Checking for missing header files..." -Color "Cyan"
    
    # Note: .inc files should be automatically generated by the build process
    # We no longer manually create them to ensure they are properly generated
    Write-Log "Skipping manual creation of .inc files - they should be generated by build process" -Color "Yellow"
}

# Enhanced function to fix NVGPU dialect registration issue
function Fix-NVGPU-Dialect-Registration {
    Write-Log "Fixing NVGPU dialect registration issue..." -Color "Cyan"
    
    # Path to the problematic header files
    $nvgpuEnumsPath = "third_party\nvidia\include\Dialect\NVGPU\IR\NVGPUEnums.h"
    $nvgpuDialectPath = "third_party\nvidia\include\Dialect\NVGPU\IR\Dialect.h"
    
    # Fix NVGPUEnums.h
    if (Test-Path $nvgpuEnumsPath) {
        Write-Log "Found NVGPUEnums.h at: $nvgpuEnumsPath" -Color "Gray"
        
        # Read the current content
        $content = Get-Content $nvgpuEnumsPath -Raw
        
        # Check if the fix is already applied
        if ($content -match "NVGPU_OPS_ENUMS_INCLUDED") {
            Write-Log "NVGPUEnums.h dialect registration fix already applied" -Color "Green"
        } else {
            # Apply the fix by adding proper include guards
            $fixedContent = @"
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
            
            # Write the fixed content
            try {
                Set-Content -Path $nvgpuEnumsPath -Value $fixedContent -Force
                Write-Log "Applied NVGPU dialect registration fix to $nvgpuEnumsPath" -Color "Green"
            } catch {
                Write-Log "Failed to apply NVGPU dialect registration fix: $($_.Exception.Message)" -Color "Red"
                return $false
            }
        }
    } else {
        Write-Log "Warning: NVGPUEnums.h not found at $nvgpuEnumsPath" -Color "Yellow"
        return $false
    }
    
    # Fix Dialect.h to add guards around NVGPUEnums.h include
    if (Test-Path $nvgpuDialectPath) {
        Write-Log "Found Dialect.h at: $nvgpuDialectPath" -Color "Gray"
        
        # Read the current content
        $content = Get-Content $nvgpuDialectPath -Raw
        
        # Check if the fix is already applied
        if ($content -match "NVGPU_ENUMS_ALREADY_INCLUDED") {
            Write-Log "Dialect.h dialect registration fix already applied" -Color "Green"
            return $true
        }
        
        # Apply the fix by adding guards around the NVGPUEnums.h include
        if ($content -match '#include "NVGPUEnums.h"') {
            $fixedContent = $content -replace '#include "NVGPUEnums.h"', @'
// Include enum declarations before the ops with proper guards
#ifndef NVGPU_ENUMS_ALREADY_INCLUDED
#define NVGPU_ENUMS_ALREADY_INCLUDED
#include "NVGPUEnums.h"
#endif
'@
            
            # Write the fixed content
            try {
                Set-Content -Path $nvgpuDialectPath -Value $fixedContent -Force
                Write-Log "Applied NVGPU dialect header fix to $nvgpuDialectPath" -Color "Green"
                return $true
            } catch {
                Write-Log "Failed to apply NVGPU dialect header fix: $($_.Exception.Message)" -Color "Red"
                return $false
            }
        } else {
            Write-Log "Warning: Could not find NVGPUEnums.h include in Dialect.h" -Color "Yellow"
            return $false
        }
    } else {
        Write-Log "Warning: Dialect.h not found at $nvgpuDialectPath" -Color "Yellow"
        return $false
    }
    
    return $true
}

# New function to clean generated files that might cause NVGPU conflicts
function Clean-NVGPU-Generated-Files {
    Write-Log "Cleaning NVGPU generated files that might cause conflicts..." -Color "Cyan"
    
    # List of generated files that might cause NVGPU dialect conflicts
    $generatedFiles = @(
        "third_party\nvidia\include\Dialect\NVGPU\IR\NVGPUOpsEnums.h.inc",
        "third_party\nvidia\include\Dialect\NVGPU\IR\NVGPUOpsEnums.cpp.inc",
        "third_party\nvidia\include\Dialect\NVGPU\IR\NVGPUAttrEnums.h.inc",
        "third_party\nvidia\include\Dialect\NVGPU\IR\NVGPUAttrEnums.cpp.inc"
    )
    
    foreach ($file in $generatedFiles) {
        if (Test-Path $file) {
            try {
                Remove-Item -Path $file -Force
                Write-Log "Removed generated file: $file" -Color "Green"
            } catch {
                Write-Log "Warning: Could not remove $file : $($_.Exception.Message)" -Color "Yellow"
            }
        }
    }
    
    Write-Log "NVGPU generated files cleanup completed" -Color "Green"
}

function Clean-BuildDirectory {
    param([string]$buildDir)
    
    Write-Log "Cleaning build directory: $buildDir" -Color "Cyan"
    
    if (Test-Path $buildDir) {
        try {
            Remove-Item -Path $buildDir -Recurse -Force
            Write-Log "Cleaned build directory successfully" -Color "Green"
        } catch {
            Write-Log "Warning: Could not clean build directory completely" -Color "Yellow"
        }
    }
    
    # Create build directory
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
    Write-Log "Created build directory: $buildDir" -Color "Green"
}

# Enhanced Configure-CMake function
function Configure-CMake {
    param([string]$buildDir, [bool]$disableNvidia)
    
    Write-Log "Configuring CMake in $buildDir..." -Color "Cyan"
    
    # Create build directory if it doesn't exist
    if (-not (Test-Path $buildDir)) {
        New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
        Write-Log "Created build directory: $buildDir" -Color "Gray"
    }
    
    # Change to build directory
    Push-Location $buildDir
    
    try {
        # Set CMake options
        $cmakeArgs = @(
            "..",
            "-G", "Ninja"
        )
        
        # Add CMAKE_MAKE_PROGRAM to use local Ninja installation
        $ninjaPath = Resolve-Path "..\ninja-install\ninja.exe"
        if (Test-Path $ninjaPath) {
            $cmakeArgs += "-DCMAKE_MAKE_PROGRAM=$ninjaPath"
            Write-Log "Using Ninja from: $ninjaPath" -Color "Green"
        }
        
        # Add NVIDIA backend options
        if ($disableNvidia) {
            $cmakeArgs += "-DTRITON_DISABLE_NVIDIA_BACKEND=ON"
            Write-Log "NVIDIA backend disabled" -Color "Yellow"
        } else {
            $cmakeArgs += "-DTRITON_DISABLE_NVIDIA_BACKEND=OFF"
            $cmakeArgs += "-DTRITON_CODEGEN_BACKENDS=nvidia"
            Write-Log "NVIDIA backend enabled" -Color "Green"
        }
        
        # Add other build options
        $cmakeArgs += @(
            "-DCMAKE_BUILD_TYPE=Release",
            "-DTRITON_BUILD_PYTHON_MODULE=ON",
            "-DTRITON_BUILD_WITH_NVWS=ON"
        )
        
        # Add LLVM/MLIR paths if available
        if ($env:LLVM_DIR) {
            $cmakeArgs += "-DLLVM_DIR=$env:LLVM_DIR"
        }
        if ($env:MLIR_DIR) {
            $cmakeArgs += "-DMLIR_DIR=$env:MLIR_DIR"
        }
        
        # Add pybind11 path
        $pybind11Path = Find-Pybind11
        if ($pybind11Path) {
            $cmakeArgs += "-Dpybind11_DIR=$pybind11Path"
        }
        
        # Add CUDA path if available and NVIDIA is enabled
        if (-not $disableNvidia) {
            $cudaPath = Find-CudaToolkit
            if ($cudaPath) {
                $cmakeArgs += "-DCUDA_TOOLKIT_ROOT_DIR=$cudaPath"
            }
        }
        
        Write-Log "Running CMake with args: $($cmakeArgs -join ' ')" -Color "Gray"
        
        # Run CMake
        & cmake @cmakeArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Log "CMake configuration successful" -Color "Green"
            return $true
        } else {
            Write-Log "CMake configuration failed" -Color "Red"
            return $false
        }
    } catch {
        Write-Log "CMake configuration failed with exception: $($_.Exception.Message)" -Color "Red"
        return $false
    } finally {
        Pop-Location
    }
}

# Enhanced Build-Triton function with better error handling
function Build-Triton {
    param([string]$buildDir, [int]$timeout)
    
    Write-Log "Building Triton in $buildDir..." -Color "Cyan"
    
    # Change to build directory (using absolute path)
    $absoluteBuildDir = Resolve-Path $buildDir
    Write-Log "Using absolute path: $absoluteBuildDir" -Color "Yellow"
    Push-Location $absoluteBuildDir
    
    try {
        # Run the build with timeout
        Write-Log "Starting build process..." -Color "Yellow"
        
        # Find Visual Studio path for vcvars setup
        $vsPath = Find-VisualStudio
        $vcVarsPath = "$vsPath\VC\Auxiliary\Build\vcvars64.bat"
        
        # Ensure CUDA paths are properly set in environment
        if (-not $DisableNvidia) {
            $cudaPath = Find-CudaToolkit
            if ($cudaPath) {
                # Add CUDA paths to environment
                $env:CUDA_PATH = $cudaPath
                $env:PATH = "$cudaPath\bin;$env:PATH"
                
                # Set CUDA library path for linking
                $env:CUDA_LIB_PATH = "$cudaPath\lib\x64"
                Write-Log "CUDA paths set: $cudaPath" -Color "Green"
            }
        }
        
        $job = Start-Job -ScriptBlock {
            param($buildDir, $vcVarsPath, $cudaPath)
            Set-Location $buildDir
            
            # Set up Visual Studio environment within the job
            if (Test-Path $vcVarsPath) {
                # Run vcvars64.bat and capture the environment
                $envVars = cmd /c """$vcVarsPath"" && set"
                foreach ($line in $envVars) {
                    if ($line -match "^(.+)=(.*)$") {
                        $varName = $matches[1]
                        $varValue = $matches[2]
                        [System.Environment]::SetEnvironmentVariable($varName, $varValue, "Process")
                    }
                }
            }
            
            # Set CUDA paths in the job environment
            if ($cudaPath) {
                $env:CUDA_PATH = $cudaPath
                $env:PATH = "$cudaPath\bin;$env:PATH"
                $env:CUDA_LIB_PATH = "$cudaPath\lib\x64"
            }
            
            # Run the build
            Write-Host "Starting Ninja build..."
            $result = & ninja -v 2>&1
            Write-Host "Ninja build output:"
            Write-Host $result
            return $LASTEXITCODE
        } -ArgumentList $absoluteBuildDir, $vcVarsPath, $cudaPath
        
        # Wait for the job to complete with timeout
        $waitResult = Wait-Job $job -Timeout $timeout
        if ($waitResult -eq $null) {
            Write-Log "Build timed out after $timeout seconds" -Color "Red"
            Stop-Job $job
            Remove-Job $job
            return $false
        }
        
        # Get the job results
        $jobResult = Receive-Job $job
        Remove-Job $job
        
        if ($jobResult -eq 0) {
            Write-Log "Build completed successfully" -Color "Green"
            return $true
        } else {
            Write-Log "Build failed with exit code: $jobResult" -Color "Red"
            return $false
        }
    } catch {
        Write-Log "Build failed with exception: $($_.Exception.Message)" -Color "Red"
        if ($job -and $job.State -eq "Running") {
            Stop-Job $job
            Remove-Job $job
        }
        return $false
    } finally {
        Pop-Location
    }
}

# New function to create Python wheel
function Create-Python-Wheel {
    param([string]$buildDir)
    
    Write-Log "Creating Python wheel..." -Color "Cyan"
    
    # Change to build directory
    Push-Location $buildDir
    
    try {
        # Run Python setup to create wheel
        Write-Log "Running Python setup.py bdist_wheel..." -Color "Gray"
        & python setup.py bdist_wheel
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Python wheel created successfully" -Color "Green"
            return $true
        } else {
            Write-Log "Failed to create Python wheel" -Color "Red"
            return $false
        }
    } catch {
        Write-Log "Failed to create Python wheel with exception: $($_.Exception.Message)" -Color "Red"
        return $false
    } finally {
        Pop-Location
    }
}

# New function to install Python wheel
function Install-Python-Wheel {
    param([string]$buildDir)
    
    Write-Log "Installing Python wheel..." -Color "Cyan"
    
    # Change to build directory
    Push-Location $buildDir
    
    try {
        # Find the wheel file
        $wheelFiles = Get-ChildItem -Path "dist" -Filter "*.whl" -ErrorAction SilentlyContinue
        if ($wheelFiles.Count -eq 0) {
            Write-Log "No wheel files found in dist directory" -Color "Red"
            return $false
        }
        
        $wheelFile = $wheelFiles[0].FullName
        Write-Log "Installing wheel: $wheelFile" -Color "Gray"
        
        # Install the wheel
        & pip install $wheelFile --force-reinstall
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Python wheel installed successfully" -Color "Green"
            return $true
        } else {
            Write-Log "Failed to install Python wheel" -Color "Red"
            return $false
        }
    } catch {
        Write-Log "Failed to install Python wheel with exception: $($_.Exception.Message)" -Color "Red"
        return $false
    } finally {
        Pop-Location
    }
}

# New function to run tests
function Run-Tests {
    param([string]$buildDir)
    
    Write-Log "Running tests..." -Color "Cyan"
    
    # Change to build directory
    Push-Location $buildDir
    
    try {
        # Run Python tests
        Write-Log "Running Python tests..." -Color "Gray"
        & python -m pytest test/python/test_language.py -v
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Python tests passed" -Color "Green"
            return $true
        } else {
            Write-Log "Python tests failed" -Color "Red"
            return $false
        }
    } catch {
        Write-Log "Failed to run tests with exception: $($_.Exception.Message)" -Color "Red"
        return $false
    } finally {
        Pop-Location
    }
}

# ----------------------------------------
# Main Execution
# ----------------------------------------

Write-Log "Triton Windows Build Script" -Color "Cyan"
Write-Log "=========================" -Color "Cyan"

# Validate parameters
if ($ForceRebuild -and $CleanBuild) {
    Write-Log "Warning: Both ForceRebuild and CleanBuild specified. CleanBuild will be used." -Color "Yellow"
}

# Find Python
$pythonExe = Find-Python $PythonPath
if (-not $pythonExe) {
    Write-ErrorAndExit "Python not found. Please install Python 3.10 or later."
}

Write-Log "Using Python: $pythonExe" -Color "Green"

# Setup Visual Studio environment
if (-not (Setup-VSEnvironment)) {
    Write-ErrorAndExit "Failed to setup Visual Studio environment."
}

# Find CUDA Toolkit
if (-not $DisableNvidia) {
    $cudaPath = Find-CudaToolkit
    if (-not $cudaPath) {
        Write-Log "Warning: CUDA Toolkit not found. Building without NVIDIA support." -Color "Yellow"
        $DisableNvidia = $true
    } else {
        Write-Log "Using CUDA Toolkit: $cudaPath" -Color "Green"
    }
}

# Find LLVM/MLIR
$llvmPath = Find-LLVM
if ($llvmPath) {
    Setup-LLVMEnvironment $llvmPath
} else {
    Write-Log "Warning: LLVM/MLIR not found. Build may fail." -Color "Yellow"
}

# Find pybind11
$pybind11Path = Find-Pybind11
if (-not $pybind11Path) {
    Write-Log "Warning: pybind11 not found. Build may fail." -Color "Yellow"
}

# Set build directory
$buildDir = "build_vs"
if ($CleanBuild -or $ForceRebuild) {
    Clean-BuildDirectory $buildDir
}

# Fix NVGPU dialect registration issue
if (-not $DisableNvidia) {
    Write-Log "Applying NVGPU dialect registration fix..." -Color "Cyan"
    if (-not (Fix-NVGPU-Dialect-Registration)) {
        Write-Log "Warning: Failed to apply NVGPU dialect registration fix." -Color "Yellow"
    }
    
    # Clean generated files that might cause conflicts
    Clean-NVGPU-Generated-Files
}

# Configure with CMake
Write-Log "Configuring with CMake..." -Color "Cyan"
if (-not (Configure-CMake $buildDir $DisableNvidia)) {
    Write-ErrorAndExit "CMake configuration failed."
}

# Build Triton
Write-Log "Building Triton..." -Color "Cyan"
if (-not (Build-Triton $buildDir $BuildTimeout)) {
    Write-ErrorAndExit "Build failed."
}

# Create Python wheel if requested
if ($CreateWheel) {
    Write-Log "Creating Python wheel..." -Color "Cyan"
    if (-not (Create-Python-Wheel ".")) {
        Write-ErrorAndExit "Failed to create Python wheel."
    }
    
    # Install the wheel
    Write-Log "Installing Python wheel..." -Color "Cyan"
    if (-not (Install-Python-Wheel ".")) {
        Write-ErrorAndExit "Failed to install Python wheel."
    }
}

# Run tests if not skipped
if (-not $SkipTests) {
    Write-Log "Running tests..." -Color "Cyan"
    if (-not (Run-Tests ".")) {
        Write-Log "Warning: Tests failed." -Color "Yellow"
    }
}

Write-Log "Build completed successfully!" -Color "Green"
Write-Log "===========================" -Color "Green"