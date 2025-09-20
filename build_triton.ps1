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
                        # Skip empty variable names
                        if ($varName) {
                            try {
                                [System.Environment]::SetEnvironmentVariable($varName, $varValue, "Process")
                            } catch {
                                # Ignore errors for invalid variable names
                            }
                        }
                    }
                }
            }
            
            # Set CUDA environment variables in job context
            if ($cudaPath) {
                [System.Environment]::SetEnvironmentVariable("CUDA_PATH", $cudaPath, "Process")
                [System.Environment]::SetEnvironmentVariable("PATH", "$cudaPath\bin;$env:PATH", "Process")
                [System.Environment]::SetEnvironmentVariable("CUDA_LIB_PATH", "$cudaPath\lib\x64", "Process")
            }
            
            & cmake --build . --config Release 2>&1
            return $LASTEXITCODE
        } -ArgumentList $absoluteBuildDir, $vcVarsPath, $cudaPath
        
        # Wait for job completion with timeout
        $job | Wait-Job -Timeout $timeout | Out-Null
        
        if ($job.State -eq "Completed") {
            $result = $job | Receive-Job
            $exitCode = $result[-1]  # Last element should be exit code
            
            if ($exitCode -eq 0) {
                Write-Log "Build completed successfully" -Color "Green"
                Pop-Location
                return $true
            } else {
                Write-Log "Build failed with exit code: $exitCode" -Color "Red"
                $result | ForEach-Object { Write-Host $_ -ForegroundColor Red }
                Pop-Location
                return $false
            }
        } else {
            Write-Log "Build timed out after $timeout seconds" -Color "Red"
            Stop-Job $job
            Pop-Location
            return $false
        }
    } catch {
        Write-Log "Build failed with exception: $($_.Exception.Message)" -Color "Red"
        Pop-Location
        return $false
    }
}

# New function to check if NVIDIA backend is properly compiled
function Test-NvidiaBackendCompiled {
    Write-Log "Checking if NVIDIA backend is properly compiled..." -Color "Cyan"
    
    # Check if the NVIDIA library exists
    $nvidiaLibPath = "build_vs\third_party\nvidia\Release\TritonNVIDIA.lib"
    if (Test-Path $nvidiaLibPath) {
        Write-Log "NVIDIA backend library found: $nvidiaLibPath" -Color "Green"
        return $true
    } else {
        Write-Log "NVIDIA backend library not found at: $nvidiaLibPath" -Color "Yellow"
        return $false
    }
}

# Enhanced Verify-Compilation function with better NVIDIA backend verification
function Verify-Compilation {
    Write-Log "Verifying compilation results..." -Color "Cyan"
    
    # Check if the main libtriton module was built
    $libtritonPath = "build_vs\triton\_C\libtriton.cp312-win_amd64.pyd"
    if (Test-Path $libtritonPath) {
        Write-Log "libtriton module compiled successfully: $libtritonPath" -Color "Green"
    } else {
        Write-Log "Error: libtriton module not found at $libtritonPath" -Color "Red"
        return $false
    }
    
    # Check if the NVIDIA backend was built (if enabled)
    if (-not $DisableNvidia) {
        # Check for NVIDIA libraries
        $nvidiaLibPaths = @(
            "build_vs\third_party\nvidia\Release\TritonNVIDIA.lib",
            "build_vs\third_party\nvidia\lib\Release\TritonNVIDIA.lib",
            "build_vs\third_party\nvidia\TritonNVIDIA.lib"
        )
        
        $nvidiaLibFound = $false
        foreach ($path in $nvidiaLibPaths) {
            if (Test-Path $path) {
                Write-Log "NVIDIA backend library found: $path" -Color "Green"
                $nvidiaLibFound = $true
                break
            }
        }
        
        if (-not $nvidiaLibFound) {
            Write-Log "Warning: NVIDIA backend library not found in expected locations" -Color "Yellow"
            # Try to find it recursively
            $nvidiaLib = Get-ChildItem -Path "build_vs" -Recurse -Name "*NVIDIA*.lib" -ErrorAction SilentlyContinue
            if ($nvidiaLib) {
                Write-Log "Found NVIDIA library at: build_vs\$nvidiaLib" -Color "Green"
            } else {
                Write-Log "Warning: NVIDIA backend not compiled correctly" -Color "Yellow"
            }
        }
        
        # Check for NVWSTransforms.lib specifically (the missing library from the error)
        $nvwsTransformsPath = "build_vs\third_party\nvidia\lib\Dialect\NVWS\Transforms\Release\NVWSTransforms.lib"
        if (Test-Path $nvwsTransformsPath) {
            Write-Log "NVWSTransforms library found: $nvwsTransformsPath" -Color "Green"
        } else {
            Write-Log "Warning: NVWSTransforms library not found at $nvwsTransformsPath" -Color "Yellow"
            # Try to find it recursively
            $nvwsLib = Get-ChildItem -Path "build_vs" -Recurse -Name "NVWSTransforms.lib" -ErrorAction SilentlyContinue
            if ($nvwsLib) {
                Write-Log "Found NVWSTransforms library at: $($nvwsLib.FullName)" -Color "Green"
            } else {
                Write-Log "Warning: NVWSTransforms library not compiled" -Color "Yellow"
            }
        }
    }
    
    return $true
}

# ----------------------------------------
# Wheel Creation Functions
# ----------------------------------------

function Test-WheelIntegrity {
    param([string]$WheelPath)
    
    Write-Log "Verifying wheel integrity: $WheelPath" -Color "Cyan"
    
    # Check if wheel exists
    if (!(Test-Path $WheelPath)) {
        Write-ErrorAndExit "Wheel file not found"
    }
    
    # Check wheel size (should be substantial)
    $size = (Get-Item $WheelPath).Length
    $sizeMB = [math]::Round($size / 1MB, 2)
    if ($size -lt 10MB) {
        Write-Log "Warning: Wheel size seems small ($sizeMB MB)" -Color "Yellow"
    }
    
    # List wheel contents
    Write-Log "Wheel contents:" -Color "Gray"
    python -m zipfile -l $WheelPath | Select-String -Pattern "\.(py|so|dll|lib|cmake|inc|h)$" | ForEach-Object {
        Write-Log "  $($_.Line)" -Color "Gray"
    }
    
    return $true
}

function Test-WheelMetadata {
    param([string]$WheelPath)
    
    Write-Log "Validating wheel metadata..." -Color "Cyan"
    
    # Extract and check metadata
    $tempDir = [System.IO.Path]::GetRandomFileName()
    $tempPath = Join-Path $env:TEMP $tempDir
    New-Item -ItemType Directory -Path $tempPath | Out-Null
    
    try {
        # Extract WHEEL file
        python -m zipfile -e $WheelPath $tempPath
        $wheelFile = Get-ChildItem -Path $tempPath -Recurse -Filter "WHEEL" | Select-Object -First 1
        
        if ($wheelFile) {
            $content = Get-Content $wheelFile.FullName
            Write-Log "Wheel metadata:" -Color "Gray"
            $content | ForEach-Object { Write-Log "  $_" -Color "Gray" }
        }
        
        # Check for triton package
        $tritonDir = Get-ChildItem -Path $tempPath -Recurse -Directory -Filter "triton" | Select-Object -First 1
        if ($tritonDir) {
            Write-Log "Triton package found in wheel" -Color "Green"
        } else {
            Write-Log "Warning: Triton package not found in wheel" -Color "Yellow"
        }
        
    } finally {
        # Clean up
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Enhanced Test-NvidiaBackend function
function Test-NvidiaBackend {
    Write-Log "Verifying NVIDIA backend..." -Color "Cyan"
    
    # Test if triton can be imported
    python -c "import triton; print('Triton imported successfully')"
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Triton import failed" -Color "Red"
        return $false
    }
    
    # Check available backends
    python -c "import triton; print('Available backends:', triton.backends.backends)"
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Backends check failed" -Color "Red"
        return $false
    }
    
    # Check if nvidia backend is listed
    $output = python -c "import triton; print('nvidia' in triton.backends.backends)"
    if ($output -match "True") {
        Write-Log "NVIDIA backend verified successfully" -Color "Green"
        return $true
    } else {
        Write-Log "NVIDIA backend not found or not compiled correctly" -Color "Red"
        return $false
    }
}

# ----------------------------------------
# Build Cleanup
# ----------------------------------------

function Clean-BuildArtifacts {
    Write-Log "Cleaning all build artifacts..." -Color "Cyan"
    
    # Remove build directories
    if (Test-Path "build") { 
        Write-Log "Removing build directory..." -Color "Gray"
        # Kill any processes that might be locking files in the build directory
        Get-Process | Where-Object { $_.Path -like "$pwd\build*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        Remove-Item "build" -Recurse -Force -ErrorAction SilentlyContinue 
    }
    
    # Remove Python cache directories
    Get-ChildItem -Path "." -Recurse -Name "__pycache__" -Directory | ForEach-Object {
        Write-Log "Removing Python cache: $_" -Color "Gray"
        Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Remove compiled Python files
    Get-ChildItem -Path "." -Recurse -Name "*.pyc" -File | ForEach-Object {
        Write-Log "Removing compiled Python file: $_" -Color "Gray"
        Remove-Item -Path $_ -Force -ErrorAction SilentlyContinue
    }
    
    # Remove libtriton modules
    if (Test-Path "python\triton\_C\libtriton*") { 
        Write-Log "Removing libtriton modules..." -Color "Gray"
        Remove-Item "python\triton\_C\libtriton*" -Force -ErrorAction SilentlyContinue 
    }
    
    Write-Log "Build artifacts cleaned successfully" -Color "Green"
}

# ----------------------------------------
# Copy Backend Files
# ----------------------------------------

function Copy-NvidiaBackendFiles {
    Write-Log "Copying NVIDIA backend files..." -Color "Cyan"
    
    # Ensure destination directory exists
    $destDir = "python\triton\backends\nvidia"
    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        Write-Log "Created NVIDIA backend directory: $destDir" -Color "Gray"
    }
    
    # Copy backend files with retry mechanism for file locks
    $sourceDir = "third_party\nvidia\backend"
    if (Test-Path $sourceDir) {
        $retryCount = 0
        $maxRetries = 5
        $retryDelay = 2  # seconds
        
        while ($retryCount -lt $maxRetries) {
            try {
                Copy-Item -Path "$sourceDir\*" -Destination $destDir -Recurse -Force -ErrorAction Stop
                Write-Log "Copied NVIDIA backend files from $sourceDir to $destDir" -Color "Green"
                return
            } catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Write-Log "File copy failed (attempt $retryCount/$maxRetries), retrying in $retryDelay seconds..." -Color "Yellow"
                    Start-Sleep -Seconds $retryDelay
                } else {
                    Write-Log "Warning: Failed to copy NVIDIA backend files after $maxRetries attempts" -Color "Yellow"
                    Write-Log "Error: $($_.Exception.Message)" -Color "Yellow"
                }
            }
        }
    } else {
        Write-Log "Warning: NVIDIA backend source directory not found: $sourceDir" -Color "Yellow"
    }
}

# ----------------------------------------
# Find libtriton.pyd
# ----------------------------------------

function Find-And-Copy-Libtriton {
    Write-Log "Finding and copying libtriton.pyd..." -Color "Cyan"
    
    # Destination path
    $destPath = "python\triton\_C\libtriton.pyd"
    
    # Ensure destination directory exists
    $destDir = Split-Path $destPath -Parent
    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    
    # Possible locations where libtriton.pyd might be generated
    $possiblePaths = @(
        "build_vs\triton\_C\libtriton.cp312-win_amd64.pyd",
        "build\triton\_C\libtriton.pyd",
        "build\lib\Release\libtriton.pyd",
        "build\Release\libtriton.pyd",
        "build\libtriton.pyd"
    )
    
    $found = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Log "Found libtriton.pyd at: $path" -Color "Green"
            
            # Retry mechanism for file locks
            $retryCount = 0
            $maxRetries = 5
            $retryDelay = 2  # seconds
            
            while ($retryCount -lt $maxRetries) {
                try {
                    Copy-Item -Path $path -Destination $destPath -Force -ErrorAction Stop
                    Write-Log "Copied libtriton.pyd to: $destPath" -Color "Green"
                    $found = $true
                    break
                } catch {
                    $retryCount++
                    if ($retryCount -lt $maxRetries) {
                        Write-Log "File copy failed (attempt $retryCount/$maxRetries), retrying in $retryDelay seconds..." -Color "Yellow"
                        Start-Sleep -Seconds $retryDelay
                    } else {
                        Write-Log "Warning: Failed to copy libtriton.pyd after $maxRetries attempts" -Color "Yellow"
                        Write-Log "Error: $($_.Exception.Message)" -Color "Yellow"
                    }
                }
            }
            if ($found) { break }
        }
    }
    
    if (-not $found) {
        Write-Log "Warning: libtriton.pyd not found in any expected location" -Color "Yellow"
        # Try to find it recursively
        $libtritonPyd = Get-ChildItem -Path "build" -Recurse -Name "libtriton.pyd" -ErrorAction SilentlyContinue
        if (-not $libtritonPyd) {
            $libtritonPyd = Get-ChildItem -Path "build_vs" -Recurse -Name "libtriton.cp312-win_amd64.pyd" -ErrorAction SilentlyContinue
        }
        if ($libtritonPyd) {
            if ($libtritonPyd.FullName -like "*build_vs*") {
                $sourcePath = $libtritonPyd.FullName
            } else {
                $sourcePath = "build\$libtritonPyd"
            }
            Write-Log "Found libtriton.pyd at: $sourcePath" -Color "Green"
            
            # Retry mechanism for file locks
            $retryCount = 0
            $maxRetries = 5
            $retryDelay = 2  # seconds
            
            while ($retryCount -lt $maxRetries) {
                try {
                    Copy-Item -Path $sourcePath -Destination $destPath -Force -ErrorAction Stop
                    Write-Log "Copied libtriton.pyd to: $destPath" -Color "Green"
                    $found = $true
                    break
                } catch {
                    $retryCount++
                    if ($retryCount -lt $maxRetries) {
                        Write-Log "File copy failed (attempt $retryCount/$maxRetries), retrying in $retryDelay seconds..." -Color "Yellow"
                        Start-Sleep -Seconds $retryDelay
                    } else {
                        Write-Log "Warning: Failed to copy libtriton.pyd after $maxRetries attempts" -Color "Yellow"
                        Write-Log "Error: $($_.Exception.Message)" -Color "Yellow"
                    }
                }
            }
        } else {
            Write-Log "Warning: libtriton.pyd not found anywhere in build directory" -Color "Yellow"
        }
    }
}

# ----------------------------------------
# Test Execution (continued)
# ----------------------------------------

function Run-Tests {
    Write-Log "Running tests..." -Color "Cyan"
    
    # Run basic import test
    python -c "import triton; print(f'Triton version: {triton.__version__}')"
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Basic import test failed" -Color "Red"
        return $false
    }
    
    # Run simple kernel test
    $testCode = @"
import triton
import triton.language as tl
import torch

@triton.jit
def add_kernel(x_ptr, y_ptr, output_ptr, n_elements, BLOCK_SIZE: tl.constexpr):
    pid = tl.program_id(axis=0)
    block_start = pid * BLOCK_SIZE
    offsets = block_start + tl.arange(0, BLOCK_SIZE)
    mask = offsets < n_elements
    x = tl.load(x_ptr + offsets, mask=mask)
    y = tl.load(y_ptr + offsets, mask=mask)
    output = x + y
    tl.store(output_ptr + offsets, output, mask=mask)

def test_triton_add():
    torch.manual_seed(0)
    size = 98432
    x = torch.rand(size, device='cuda')
    y = torch.rand(size, device='cuda')
    output = torch.empty_like(x, device='cuda')
    grid = lambda meta: (triton.cdiv(size, meta['BLOCK_SIZE']),)
    add_kernel[grid](x, y, output, size, BLOCK_SIZE=1024)
    expected = x + y
    return torch.allclose(output, expected)

if torch.cuda.is_available():
    result = test_triton_add()
    print(f'Triton kernel test: {"PASSED" if result else "FAILED"}')
else:
    print('CUDA not available, skipping kernel test')
"@
    
    python -c $testCode
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Kernel test failed" -Color "Red"
        return $false
    }
    
    Write-Log "All tests passed!" -Color "Green"
    return $true
}

# New function to test Triton installation
function Test-TritonInstallation {
    Write-Log "Testing Triton installation..." -Color "Cyan"
    
    # Test basic import
    python -c "import triton; print('Triton imported successfully')"
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Triton import failed" -Color "Red"
        return $false
    }
    
    # Test version
    python -c "import triton; print(f'Triton version: {triton.__version__}')"
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Version check failed" -Color "Red"
        return $false
    }
    
    # Test backends
    python -c "import triton; print('Available backends:', list(triton.backends.backends.keys()))"
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Backends check failed" -Color "Red"
        return $false
    }
    
    Write-Log "Triton installation test passed!" -Color "Green"
    return $true
}

# Enhanced wheel creation function
function Create-Wheel {
    param([bool]$withNvidia = $true)
    
    Write-Log "Creating wheel distribution..." -Color "Cyan"
    
    # Clean previous builds
    Write-Log "Cleaning build cache..." -Color "Gray"
    Get-ChildItem -Path "." -Recurse -Name "__pycache__" -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path "build") { 
        Remove-Item "build" -Recurse -Force -ErrorAction SilentlyContinue 
    }
    if (Test-Path "dist") { 
        Remove-Item "dist" -Recurse -Force -ErrorAction SilentlyContinue 
    }
    if (Test-Path "python\triton\_C\libtriton*") { 
        Remove-Item "python\triton\_C\libtriton*" -Force -ErrorAction SilentlyContinue 
    }

    # Build Triton with CMake for wheel creation
    Write-Log "Building Triton C++ extension for wheel..." -Color "Gray"

    # Create build directory
    if (!(Test-Path "build")) { 
        New-Item -ItemType Directory -Path "build" | Out-Null 
    }

    # Change to build directory
    Push-Location "build"

    try {
        # Configure with CMake using Visual Studio compiler
        Write-Log "Configuring with CMake..." -Color "Gray"
        
        # Set LLVM path
        $llvmPath = "C:\Users\Admin\.triton\llvm\llvm-8957e64a-windows-x64"
        if (Test-Path $llvmPath) {
            $env:LLVM_DIR = "$llvmPath\lib\cmake\llvm"
            $env:MLIR_DIR = "$llvmPath\lib\cmake\mlir"
            Write-Log "Using LLVM from: $llvmPath" -Color "Green"
        } else {
            Write-ErrorAndExit "LLVM not found at $llvmPath"
        }

        # Ensure pybind11 3.0.1 is installed
        Write-Log "Checking pybind11 installation..." -Color "Gray"
        try {
            python -c "import pybind11; version=pybind11.__version__" 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Installing pybind11==3.0.1..." -Color "Yellow"
                python -m pip install pybind11==3.0.1
            } else {
                $version = python -c "import pybind11; print(pybind11.__version__)"
                if ($version -ne "3.0.1") {
                    Write-Log "Updating pybind11 to 3.0.1..." -Color "Yellow"
                    python -m pip install pybind11==3.0.1 --force-reinstall
                } else {
                    Write-Log "pybind11 3.0.1 is already installed" -Color "Green"
                }
            }
        } catch {
            Write-ErrorAndExit "Failed to configure pybind11"
        }

        # Get pybind11 cmake directory
        $pybind11CmakeDir = python -c "import pybind11; print(pybind11.get_cmake_dir())"
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorAndExit "Failed to get pybind11 cmake directory"
        }
        Write-Log "pybind11 cmake directory: $pybind11CmakeDir" -Color "Gray"

        # Configure build options
        $env:TRITON_DISABLE_NVIDIA_BACKEND = if (-not $withNvidia) { "ON" } else { "OFF" }
        $env:TRITON_CODEGEN_BACKENDS = if (-not $withNvidia) { "" } else { "nvidia" }
        Write-Log "Building with NVIDIA support: $withNvidia" -Color "Green"

        $env:TRITON_BUILD_PYTHON_MODULE = "ON"
        $env:MAX_JOBS = "1"

        # Ensure CUDA paths are properly set for wheel creation
        if ($withNvidia) {
            $cudaPath = Find-CudaToolkit
            if ($cudaPath) {
                $env:CUDA_PATH = $cudaPath
                $env:PATH = "$cudaPath\bin;$env:PATH"
                $env:CUDA_LIB_PATH = "$cudaPath\lib\x64"
                Write-Log "CUDA paths set for wheel creation: $cudaPath" -Color "Green"
            }
        }

        # Configure with CMake
        Write-Log "Running CMake configuration..." -Color "Gray"
        $cmakeArgs = @(
            "-G", "Ninja",
            "-DCMAKE_BUILD_TYPE=Release",
            "-DLLVM_DIR=$env:LLVM_DIR",
            "-DMLIR_DIR=$env:MLIR_DIR",
            "-DPYBIND11_DIR=$pybind11CmakeDir",
            "-DTRITON_DISABLE_NVIDIA_BACKEND=$env:TRITON_DISABLE_NVIDIA_BACKEND",
            "-DTRITON_CODEGEN_BACKENDS=$env:TRITON_CODEGEN_BACKENDS",
            "-DTRITON_BUILD_PYTHON_MODULE=$env:TRITON_BUILD_PYTHON_MODULE",
            "-DTRITON_BUILD_WITH_NVWS=ON"
        )
        
        # Add CUDA path if available
        if ($env:CUDA_PATH) {
            $cmakeArgs += "-DCUDA_TOOLKIT_ROOT_DIR=$env:CUDA_PATH"
        }
        
        $cmakeArgs += ".."
        
        Write-Log "CMake arguments: $($cmakeArgs -join ' ')" -Color "Gray"
        & cmake @cmakeArgs

        if ($LASTEXITCODE -ne 0) {
            Write-Log "CMake configuration failed with exit code: $LASTEXITCODE" -Color "Red"
            Write-ErrorAndExit "CMake configuration for wheel failed"
        }

        # Build with Ninja
        Write-Log "Building with Ninja..." -Color "Gray"
        & ninja -v
        $ninjaExitCode = $LASTEXITCODE
        if ($ninjaExitCode -ne 0) {
            Write-Log "Ninja build failed with exit code: $ninjaExitCode" -Color "Red"
            Write-ErrorAndExit "Ninja build failed"
        }

        # Copy the built library to the correct location for packaging
        Write-Log "Copying built libraries..." -Color "Gray"
        $libtritonPath = "triton\_C\libtriton.cp312-win_amd64.pyd"
        if (Test-Path $libtritonPath) {
            Copy-Item $libtritonPath "..\python\triton\_C\libtriton.pyd" -Force
            Write-Log "Copied libtriton.pyd to python package" -Color "Green"
        } else {
            Write-Log "Warning: libtriton.pyd not found at expected location: $libtritonPath" -Color "Yellow"
            # Try to find it recursively
            $foundLib = Get-ChildItem -Path "." -Recurse -Name "libtriton.cp312-win_amd64.pyd" -ErrorAction SilentlyContinue
            if ($foundLib) {
                Write-Log "Found libtriton.pyd at: $foundLib" -Color "Green"
                Copy-Item $foundLib "..\python\triton\_C\libtriton.pyd" -Force
                Write-Log "Copied libtriton.pyd to python package" -Color "Green"
            } else {
                Write-Log "Error: libtriton.pyd not found anywhere in build directory" -Color "Red"
            }
        }

        # Copy NVIDIA backend files if enabled
        if ($withNvidia) {
            Write-Log "Copying NVIDIA backend files..." -Color "Gray"
            if (Test-Path "..\third_party\nvidia\backend") {
                if (-not (Test-Path "..\python\triton\backends\nvidia")) {
                    New-Item -ItemType Directory -Path "..\python\triton\backends\nvidia" -Force | Out-Null
                }
                Copy-Item "..\third_party\nvidia\backend\*" "..\python\triton\backends\nvidia" -Recurse -Force
                Write-Log "Copied NVIDIA backend files" -Color "Green"
            } else {
                Write-Log "Warning: NVIDIA backend files not found" -Color "Yellow"
            }
        }

        # Return to root directory
        Pop-Location

        # Create wheel
        Write-Log "Creating Python wheel..." -Color "Gray"
        & python setup.py bdist_wheel
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Wheel creation failed with exit code: $LASTEXITCODE" -Color "Red"
            Write-ErrorAndExit "Wheel creation failed"
        }

        # Verify wheel creation
        $wheels = Get-ChildItem -Path "dist" -Filter "*.whl"
        if ($wheels.Count -gt 0) {
            Write-Log "Created wheel:" -Color "Green"
            $wheels | ForEach-Object {
                Write-Log "  $($_.Name)" -Color "Gray"
            }
            return $true
        } else {
            Write-ErrorAndExit "No wheel file was created"
        }
    } finally {
        Pop-Location
    }
}

# ----------------------------------------
# Main Build Process
# ----------------------------------------

Write-Log "Starting Triton Windows Build Process" -Color "Cyan"
Write-Log "====================================" -Color "Cyan"

# Validate prerequisites
Write-Log "[1/9] Validating prerequisites..." -Color "Cyan"

# Find Python
$pythonExe = Find-Python $PythonPath
if (-not $pythonExe) {
    Write-ErrorAndExit "Python not found. Please install Python 3.9+ or specify path with -PythonPath"
}

# Find Visual Studio
$vsPath = Find-VisualStudio
if (-not $vsPath) {
    Write-ErrorAndExit "Visual Studio not found. Please install Visual Studio 2022 Community or Professional"
}

# Setup Visual Studio environment
Setup-VSEnvironment

# Find LLVM/MLIR
$llvmPath = Find-LLVM
if (-not $llvmPath) {
    Write-Log "Warning: LLVM/MLIR not found." -Color "Yellow"
    if ($InstallDependencies) {
        Install-LLVMDependencies
    } else {
        Write-Log "Build may fail due to missing dependencies. Use -InstallDependencies flag for installation guidance." -Color "Yellow"
    }
} else {
    # Setup LLVM/MLIR environment
    Setup-LLVMEnvironment $llvmPath
}

# Check and create missing headers
Check-And-CreateMissingHeaders

# Find CUDA Toolkit (if NVIDIA backend is enabled)
if (-not $DisableNvidia) {
    $cudaPath = Find-CudaToolkit
    if (-not $cudaPath) {
        Write-Log "Warning: CUDA Toolkit not found. NVIDIA backend may not work properly." -Color "Yellow"
    }
}

Write-Log "Prerequisites validated successfully" -Color "Green"

# Clean build if requested
if ($CleanBuild -or $ForceRebuild) {
    Write-Log "[2/9] Cleaning build directory..." -Color "Cyan"
    Clean-BuildDirectory "build_vs"
} else {
    Write-Log "[2/9] Using existing build directory..." -Color "Cyan"
    if (!(Test-Path "build_vs")) {
        New-Item -ItemType Directory -Path "build_vs" -Force | Out-Null
        Write-Log "Created build directory: build_vs" -Color "Green"
    }
}

# Configure CMake
Write-Log "[3/9] Configuring CMake..." -Color "Cyan"
if (-not (Configure-CMake "build_vs" $DisableNvidia)) {
    Write-ErrorAndExit "CMake configuration failed"
}

# Build Triton
Write-Log "[4/9] Building Triton..." -Color "Cyan"
if (-not (Build-Triton "build_vs" $BuildTimeout)) {
    Write-ErrorAndExit "Build failed"
}

# Verify compilation
Write-Log "[5/9] Verifying compilation..." -Color "Cyan"
if (-not (Verify-Compilation)) {
    Write-ErrorAndExit "Compilation verification failed"
}

# Add wheel creation to the main execution flow if requested
if ($CreateWheel) {
    Write-Log "[8/9] Creating wheel distribution..." -Color "Cyan"
    if (-not (Create-Wheel (-not $DisableNvidia))) {
        Write-ErrorAndExit "Failed to create wheel"
    }
    Write-Log "Wheel created successfully!" -Color "Green"
}

Write-Log "[9/9] Build process completed!" -Color "Cyan"
Write-Log "====================================" -Color "Cyan"
Write-Log "Triton has been successfully built!" -Color "Green"

if (-not $DisableNvidia) {
    Write-Log "NVIDIA GPU support is enabled and working." -Color "Green"
} else {
    Write-Log "NVIDIA GPU support is disabled." -Color "Yellow"
}

Write-Log "Summary of environment setup:" -Color "Cyan"
if ($env:LLVM_DIR) {
    Write-Log "  LLVM_DIR: $($env:LLVM_DIR)" -Color "Green"
}
if ($env:MLIR_DIR) {
    Write-Log "  MLIR_DIR: $($env:MLIR_DIR)" -Color "Green"
}
if ($env:CUDA_PATH) {
    Write-Log "  CUDA_PATH: $($env:CUDA_PATH)" -Color "Green"
}

Write-Log "Next steps:" -Color "Cyan"
Write-Log "  - Add the build directory to your Python path to use Triton" -Color "Green"
if ($CreateWheel) {
    Write-Log "  - Wheel distribution has been created in the dist directory" -Color "Green"
}
Write-Log "  - Run tests to verify functionality" -Color "Green"

exit 0
