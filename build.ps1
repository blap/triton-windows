# Simplified Triton Windows Build Script
# This script builds Triton for Windows without error handling

Write-Host "Starting Triton build for Windows (simplified)..." -ForegroundColor Green

# Find Python installation
function Find-PythonPath {
    $pythonPaths = @(
        "C:\Program Files\Python312\python.exe",
        "C:\Program Files\Python311\python.exe",
        "C:\Program Files\Python310\python.exe",
        "C:\Python312\python.exe",
        "C:\Python311\python.exe",
        "C:\Python310\python.exe"
    )
    
    foreach ($path in $pythonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Try to find Python in PATH
    try {
        $pythonInPath = (Get-Command python -ErrorAction SilentlyContinue).Source
        if ($pythonInPath -and (Test-Path $pythonInPath)) {
            return $pythonInPath
        }
    } catch {}
    
    return $null
}

# Find Visual Studio installation
function Find-VSPath {
    $vsPaths = @(
        "C:\Program Files\Microsoft Visual Studio\2022\Professional",
        "C:\Program Files\Microsoft Visual Studio\2022\Community",
        "C:\Program Files\Microsoft Visual Studio\2022\Enterprise",
        "C:\Program Files (x86)\Microsoft Visual Studio\2022\Professional",
        "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community",
        "C:\Program Files (x86)\Microsoft Visual Studio\2022\Enterprise",
        "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
    )
    
    foreach ($path in $vsPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

# Configure environment variables for build
Write-Host "Configuring environment variables..." -ForegroundColor Cyan

# Find Python installation
$pythonExe = Find-PythonPath
if (-not $pythonExe) {
    Write-Host "Python not found. Please install Python 3.10+ or specify -PythonPath" -ForegroundColor Red
    exit 1
}
Write-Host "Using Python: $pythonExe" -ForegroundColor Green

# Find Visual Studio installation
$vsPath = Find-VSPath
if (-not $vsPath) {
    Write-Host "Visual Studio 2022 not found. Please install Visual Studio 2022" -ForegroundColor Red
    exit 1
}
Write-Host "Using Visual Studio: $vsPath" -ForegroundColor Green

# Find MSVC version dynamically
$msvcPath = Get-ChildItem "$vsPath\VC\Tools\MSVC" | Sort-Object Name -Descending | Select-Object -First 1
if (-not $msvcPath) {
    Write-Host "MSVC tools not found in Visual Studio installation" -ForegroundColor Red
    exit 1
}
$msvcVersion = $msvcPath.Name
Write-Host "Using MSVC version: $msvcVersion" -ForegroundColor Green

# Find Windows SDK version
$sdkPath = "C:\Program Files (x86)\Windows Kits\10"
if (Test-Path $sdkPath) {
    $sdkVersions = Get-ChildItem "$sdkPath\bin" | Where-Object { $_.Name -match "^10\.0\." } | Sort-Object Name -Descending
    if ($sdkVersions) {
        $sdkVersion = $sdkVersions[0].Name
        Write-Host "Using Windows SDK version: $sdkVersion" -ForegroundColor Green
    } else {
        Write-Host "Windows SDK version not found, using default" -ForegroundColor Yellow
        $sdkVersion = "10.0.20348.0"
    }
} else {
    Write-Host "Windows SDK not found" -ForegroundColor Red
    exit 1
}

# Get Python directory from executable path
$pythonDir = Split-Path $pythonExe -Parent

# Configure PATH with necessary tools
$envPaths = @(
    "C:\Windows\System32",
    $pythonDir,
    "$pythonDir\Scripts",
    "$vsPath\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin",
    "$vsPath\VC\Tools\MSVC\$msvcVersion\bin\Hostx64\x64",
    "$vsPath\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja",
    "$sdkPath\bin\$sdkVersion\x64",
    "C:\Program Files\Git\cmd"
) | Where-Object { Test-Path $_ }

$env:Path = ($envPaths -join ";") + ";" + $env:Path

# Set Visual Studio environment variables
$env:VCINSTALLDIR = "$vsPath\VC\Tools\MSVC\$msvcVersion\"
$env:WindowsSdkDir = "$sdkPath\"
$env:WindowsSDKLibVersion = "$sdkVersion\"

# Find CUDA installation (optional)
$cudaPaths = @(
    "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.9",
    "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8",
    "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.7",
    "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.6",
    "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.5"
)

$cudaPath = $null
foreach ($path in $cudaPaths) {
    if (Test-Path $path) {
        $cudaPath = $path
        Write-Host "Found CUDA: $cudaPath" -ForegroundColor Green
        break
    }
}

if (-not $cudaPath) {
    Write-Host "CUDA not found - GPU support may be limited" -ForegroundColor Yellow
}

# Configure INCLUDE paths
$includePaths = @(
    "$vsPath\VC\Tools\MSVC\$msvcVersion\include",
    "$sdkPath\Include\$sdkVersion\ucrt",
    "$sdkPath\Include\$sdkVersion\um",
    "$sdkPath\Include\$sdkVersion\shared"
)

if ($cudaPath) {
    $includePaths += "$cudaPath\include"
    $includePaths += "$cudaPath\extras\CUPTI\include"
}

$env:INCLUDE = ($includePaths | Where-Object { Test-Path $_ }) -join ";"

# Configure LIB paths
$libPaths = @(
    "$vsPath\VC\Tools\MSVC\$msvcVersion\lib\x64",
    "$sdkPath\Lib\$sdkVersion\ucrt\x64",
    "$sdkPath\Lib\$sdkVersion\um\x64"
)

$env:LIB = ($libPaths | Where-Object { Test-Path $_ }) -join ";"

# Configure Triton flags
Write-Host "Configuring Triton flags..." -ForegroundColor Cyan
$env:TRITON_OFFLINE_BUILD = '0'
$env:TRITON_BUILD_UT = '0'
$env:TRITON_BUILD_BINARY = '0'
$env:TRITON_BUILD_PROTON = '0'
$env:TRITON_BUILD_WITH_CCACHE = '0'
# Limit build to a single job to reduce resource usage
$env:MAX_JOBS = '2'

# Set LLVM paths for Triton
$llvmPath = "C:\Users\Admin\.triton\llvm\llvm-8957e64a-windows-x64"
$env:LLVM_SYSPATH = $llvmPath
$env:LLVM_INCLUDE_DIRS = "$llvmPath\include"
$env:LLVM_LIBRARY_DIR = "$llvmPath\lib"
$env:LLVM_CMAKE_DIR = "$llvmPath\lib\cmake\llvm"
$env:MLIR_CMAKE_DIR = "$llvmPath\lib\cmake\mlir"
$env:LLVM_DIR = "$llvmPath\lib\cmake\llvm"
$env:MLIR_DIR = "$llvmPath\lib\cmake\mlir"

# CMake and MSVC flags
$cmakeArgs = @(
    '-DCMAKE_CXX_STANDARD=17',
    '-DCMAKE_BUILD_TYPE=Release',
    '-DCMAKE_GENERATOR=Ninja',
    "-DLLVM_DIR=$llvmPath\lib\cmake\llvm",
    "-DMLIR_DIR=$llvmPath\lib\cmake\mlir"
)

# Add LLVM paths to CMAKE_ARGS
$env:CMAKE_ARGS = $cmakeArgs -join ' '
$env:CL = '/Zc:__cplusplus /std:c++17 /bigobj'

# Build for NVIDIA only
$env:TRITON_CODEGEN_BACKENDS = 'nvidia'

# Check required dependencies
Write-Host "Checking dependencies..." -ForegroundColor Cyan
$requiredTools = @(
    @{Name="cmake"; Path="$vsPath\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"},
    @{Name="ninja"; Path="$vsPath\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"},
    @{Name="python"; Path=$pythonExe}
)

$missingTools = @()
foreach ($tool in $requiredTools) {
    if (!(Test-Path $tool.Path)) {
        Write-Host "$($tool.Name) not found at: $($tool.Path)" -ForegroundColor Red
        $missingTools += $tool.Name
    } else {
        Write-Host "$($tool.Name) found" -ForegroundColor Green
    }
}

if ($missingTools.Count -gt 0) {
    Write-Host "Missing tools: $($missingTools -join ', ')" -ForegroundColor Red
    Write-Host "Please install the missing tools or update the paths in the script." -ForegroundColor Yellow
    exit 1
}

# Check Python version
try {
    $pythonVersion = & $pythonExe --version 2>&1
    Write-Host "Python version: $pythonVersion" -ForegroundColor Green
    
    # Check if pip is available
    $pipCheck = & $pythonExe -m pip --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "pip is available" -ForegroundColor Green
    } else {
        Write-Host "pip not found or not working" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Failed to check Python version" -ForegroundColor Red
    exit 1
}

# Show configuration summary
Write-Host "Build Configuration:" -ForegroundColor Cyan
Write-Host "   Python: $pythonExe" -ForegroundColor Gray
Write-Host "   Visual Studio: $vsPath" -ForegroundColor Gray
Write-Host "   MSVC Version: $msvcVersion" -ForegroundColor Gray
Write-Host "   Windows SDK: $sdkVersion" -ForegroundColor Gray
if ($cudaPath) {
    Write-Host "   CUDA: $cudaPath" -ForegroundColor Gray
} else {
    Write-Host "   CUDA: Not found" -ForegroundColor Gray
}
Write-Host "   CMAKE_ARGS: $env:CMAKE_ARGS" -ForegroundColor Gray
Write-Host ""

# Start build
Write-Host "Starting build process..." -ForegroundColor Cyan

# Execute build
$buildArgs = @("-m", "pip", "install", "-e", ".", "--no-cache-dir")

Write-Host "Running: $pythonExe $($buildArgs -join ' ')" -ForegroundColor Cyan

try {
    & $pythonExe @buildArgs
    $buildExitCode = $LASTEXITCODE
    
    if ($buildExitCode -eq 0) {
        Write-Host "Build completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Build failed with exit code: $buildExitCode" -ForegroundColor Red
        exit $buildExitCode
    }
} catch {
    Write-Host "Error during pip installation" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Build wheel and save to build directory
Write-Host "Building wheel and saving to build directory..." -ForegroundColor Cyan

# Ensure build directory exists
if (!(Test-Path "build")) {
    New-Item -ItemType Directory -Path "build" | Out-Null
}

# Build wheel directly to build directory
try {
    # Use absolute path for the build directory
    $buildDir = Resolve-Path "build"
    Write-Host "Building wheel to directory: $buildDir" -ForegroundColor Gray
    
    & $pythonExe -m pip wheel . --no-deps -w "$buildDir"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Wheel built successfully!" -ForegroundColor Green
        
        # List the created wheel file
        $wheelFiles = Get-ChildItem -Path "$buildDir" -Filter "*.whl" -ErrorAction SilentlyContinue
        if ($wheelFiles) {
            Write-Host "Created wheel file(s) in build directory:" -ForegroundColor Gray
            foreach ($wheelFile in $wheelFiles) {
                Write-Host "   $($wheelFile.Name)" -ForegroundColor Gray
            }
        } else {
            Write-Host "Warning: No wheel files found in build directory" -ForegroundColor Yellow
            # List all files in build directory to debug
            $allFiles = Get-ChildItem -Path "$buildDir" -ErrorAction SilentlyContinue
            if ($allFiles) {
                Write-Host "All files in build directory:" -ForegroundColor Gray
                foreach ($file in $allFiles) {
                    Write-Host "   $($file.Name)" -ForegroundColor Gray
                }
            } else {
                Write-Host "Build directory is empty" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "Failed to build wheel" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error building wheel: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "TRITON WINDOWS BUILD COMPLETED" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan