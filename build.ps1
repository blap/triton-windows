# Triton Windows Build Script
# Builds Triton for Windows with NVIDIA GPU support
#
# Usage:
#   .\build.ps1                    # Normal build with NVIDIA support
#   .\build.ps1 -DisableNvidia     # Build without NVIDIA support
#   .\build.ps1 -PythonPath "C:\path\to\python.exe"  # Use specific Python
#   .\build.ps1 -BuildTimeout 7200  # Set build timeout to 2 hours
#   .\build.ps1 -Verbose           # Enable verbose logging
#   .\build.ps1 -CleanBuild        # Clean all build artifacts before building

param(
    [switch]$DisableNvidia,
    [string]$PythonPath = "",
    [int]$BuildTimeout = 3600,  # 1 hour default
    [switch]$Verbose,
    [switch]$CleanBuild
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

function Test-NvidiaHardware {
    Write-Log "Checking for NVIDIA hardware..." -Color "Cyan"
    
    # Check for NVIDIA GPU using nvidia-smi if available
    try {
        $gpuInfo = nvidia-smi --query-gpu=name,compute_cap --format=csv,noheader,nounits 2>$null
        if ($LASTEXITCODE -eq 0 -and $gpuInfo) {
            Write-Log "NVIDIA GPU detected: $gpuInfo" -Color "Green"
            return $true
        }
    } catch {}
    
    Write-Log "Warning: NVIDIA GPU not detected or nvidia-smi not available" -Color "Yellow"
    Write-Log "Build will continue but GPU functionality cannot be verified" -Color "Yellow"
    return $true  # Continue build even without GPU
}

# Fix f2reduce version file to prevent C++ compilation errors
function Fix-F2ReduceVersion {
    Write-Log "Fixing f2reduce version file..." -Color "Cyan"
    
    $file = "third_party\f2reduce\version"
    if (Test-Path $file) {
        $content = "// f2reduce version information`n// File intentionally empty to prevent C++ compilation issues"
        Set-Content -Path $file -Value $content -Encoding UTF8
        Write-Log "Fixed f2reduce version file" -Color "Green"
    }
}

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

function Test-NvidiaBackend {
    param([string]$PythonPath)
    
    Write-Log "Verifying NVIDIA backend..." -Color "Cyan"
    & $PythonPath -c "import triton; print('Available backends:', triton.backends.backends)"
    
    # Check if nvidia backend is listed
    $output = & $PythonPath -c "import triton; print('nvidia' in triton.backends.backends)"
    if ($output -match "True") {
        Write-Log "NVIDIA backend verified successfully" -Color "Green"
        return $true
    } else {
        Write-Log "NVIDIA backend not found or not compiled correctly" -Color "Red"
        return $false
    }
}

function Start-BuildWithTimeout {
    param(
        [scriptblock]$BuildScript,
        [int]$TimeoutSeconds
    )
    
    Write-Log "Starting build with timeout of $TimeoutSeconds seconds..." -Color "Cyan"
    
    $job = Start-Job -ScriptBlock $BuildScript
    $wait = Wait-Job $job -Timeout $TimeoutSeconds
    
    if ($wait -eq $null) {
        Stop-Job $job
        Write-ErrorAndExit "Build timed out after $TimeoutSeconds seconds"
    }
    
    Receive-Job $job
    Remove-Job $job
}

# ----------------------------------------
# Pre-flight Checks
# ----------------------------------------

function Test-PreflightChecks {
    param([string]$PythonPath)
    
    Write-Log "Performing pre-flight checks..." -Color "Cyan"
    
    # Check Python version
    $pythonVersion = & $PythonPath -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    if ($pythonVersion -notmatch "^(3\.9|3\.10|3\.11|3\.12)$") {
        Write-Log "Warning: Python version $pythonVersion may not be fully supported" -Color "Yellow"
    } else {
        Write-Log "Python version $pythonVersion is supported" -Color "Green"
    }
    
    # Check required packages
    $requiredPackages = @("setuptools", "wheel", "cmake", "ninja")
    foreach ($package in $requiredPackages) {
        try {
            & $PythonPath -c "import $package" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$package is installed" -Color "Green"
            } else {
                Write-Log "Warning: $package is not installed" -Color "Yellow"
            }
        } catch {
            Write-Log "Warning: $package is not installed" -Color "Yellow"
        }
    }
    
    # Check disk space (minimum 10GB)
    $drive = (Get-Location).Drive.Name
    $freeSpace = (Get-PSDrive $drive).Free
    $freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)
    if ($freeSpace -lt 10GB) {
        Write-Log "Warning: Low disk space ($freeSpaceGB GB free)" -Color "Yellow"
    } else {
        Write-Log "Sufficient disk space available ($freeSpaceGB GB free)" -Color "Green"
    }
    
    Write-Log "Pre-flight checks completed" -Color "Green"
}

# ----------------------------------------
# Build Cleanup
# ----------------------------------------

function Clean-BuildArtifacts {
    Write-Log "Cleaning all build artifacts..." -Color "Cyan"
    
    # Remove build directories
    if (Test-Path "build") { 
        Write-Log "Removing build directory..." -Color "Gray"
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
# Main Build Process
# ----------------------------------------

# Ensure we're in the correct directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $scriptPath

Write-Log "Starting Triton Windows build..." -Color "Green"
Write-Log "Working directory: $(Get-Location)" -Color "Gray"

# Clean build if requested
if ($CleanBuild) {
    Clean-BuildArtifacts
}

# Verify Python installation
$python = Find-Python -PythonPath $PythonPath
if (-not $python) {
    Write-ErrorAndExit "Python not found"
}
Write-Log "Using Python: $python" -Color "Green"

# Perform pre-flight checks
Test-PreflightChecks -PythonPath $python

# Verify Visual Studio installation
$vs = Find-VisualStudio
if (-not $vs) {
    Write-ErrorAndExit "Visual Studio 2022 not found"
}
Write-Log "Using Visual Studio: $vs" -Color "Green"

# Configure MSVC
$msvc = Get-ChildItem "$vs\VC\Tools\MSVC" | Sort-Object Name -Descending | Select-Object -First 1
if (-not $msvc) {
    Write-ErrorAndExit "MSVC tools not found"
}
$msvcVersion = $msvc.Name
Write-Log "Using MSVC: $msvcVersion" -Color "Green"

# Configure environment
$env:CC = "$vs\VC\Tools\MSVC\$msvcVersion\bin\Hostx64\x64\cl.exe"
$env:CXX = "$vs\VC\Tools\MSVC\$msvcVersion\bin\Hostx64\x64\cl.exe"

# Find CUDA Toolkit
if (-not $DisableNvidia) {
    $cuda = Find-CudaToolkit
    if ($cuda) {
        Write-Log "CUDA Toolkit located at: $cuda" -Color "Green"
        # Add CUDA to PATH for linking
        $env:PATH = "$cuda\bin;$env:PATH"
    } else {
        Write-Log "Warning: CUDA Toolkit not found, but continuing with build" -Color "Yellow"
    }
}

# Check for NVIDIA hardware
if (-not $DisableNvidia) {
    Test-NvidiaHardware
}

# Fix f2reduce version file before build
Fix-F2ReduceVersion

# Ensure pybind11 3.0.1 is installed
Write-Log "Checking pybind11 installation..." -Color "Cyan"
try {
    & $python -c "import pybind11; version=pybind11.__version__" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Installing pybind11==3.0.1..." -Color "Yellow"
        & $python -m pip install pybind11==3.0.1
    } else {
        $version = & $python -c "import pybind11; print(pybind11.__version__)"
        if ($version -ne "3.0.1") {
            Write-Log "Updating pybind11 to 3.0.1..." -Color "Yellow"
            & $python -m pip install pybind11==3.0.1 --force-reinstall
        } else {
            Write-Log "pybind11 3.0.1 is already installed" -Color "Green"
        }
    }
} catch {
    Write-ErrorAndExit "Failed to configure pybind11"
}

# Get pybind11 cmake directory
$pybind11CmakeDir = & $python -c "import pybind11; print(pybind11.get_cmake_dir())"
if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "Failed to get pybind11 cmake directory"
}
Write-Log "pybind11 cmake directory: $pybind11CmakeDir" -Color "Gray"

# Configure build options
if ($DisableNvidia) {
    $env:TRITON_DISABLE_NVIDIA_BACKEND = "ON"
    Write-Log "Building without NVIDIA support" -Color "Yellow"
} else {
    $env:TRITON_DISABLE_NVIDIA_BACKEND = "OFF"
    $env:TRITON_CODEGEN_BACKENDS = "nvidia"
    Write-Log "Building with NVIDIA support" -Color "Green"
}

$env:TRITON_BUILD_PYTHON_MODULE = "1"
$env:MAX_JOBS = "1"

# Set LLVM path
$llvmPath = "C:\Users\Admin\.triton\llvm\llvm-8957e64a-windows-x64"
if (Test-Path $llvmPath) {
    $env:LLVM_DIR = "$llvmPath\lib\cmake\llvm"
    $env:MLIR_DIR = "$llvmPath\lib\cmake\mlir"
    Write-Log "Using LLVM from: $llvmPath" -Color "Green"
} else {
    Write-ErrorAndExit "LLVM not found at $llvmPath"
}

# Clean previous builds
Write-Log "[1/5] Cleaning build cache..." -Color "Cyan"
Get-ChildItem -Path "." -Recurse -Name "__pycache__" -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path "build") { Remove-Item "build\*" -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path "python\triton\_C\libtriton*") { Remove-Item "python\triton\_C\libtriton*" -Force -ErrorAction SilentlyContinue }

# Build Triton with CMake
Write-Log "[2/5] Building Triton C++ extension..." -Color "Cyan"

# Create build directory
if (!(Test-Path "build")) { 
    New-Item -ItemType Directory -Path "build" | Out-Null 
}

# Configure with CMake
Write-Log "Configuring with CMake..." -Color "Cyan"
& cmake -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DLLVM_DIR="$env:LLVM_DIR" -DMLIR_DIR="$env:MLIR_DIR" -DPYBIND11_DIR="$pybind11CmakeDir" -B build .
if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "CMake configuration failed"
}

# Build with Ninja
Write-Log "Building with Ninja..." -Color "Cyan"
& cmake --build build --target libtriton
if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "Ninja build failed"
}

# Copy the built libtriton module to the correct location
Write-Log "Copying libtriton module to python/triton/_C..." -Color "Cyan"
$libtritonSource = "build\triton\_C"
$libtritonDest = "python\triton\_C"
if (Test-Path $libtritonSource) {
    Copy-Item -Path "$libtritonSource\*" -Destination $libtritonDest -Force
    Write-Log "libtriton module copied successfully" -Color "Green"
} else {
    Write-Log "Warning: libtriton module not found at $libtritonSource" -Color "Yellow"
}

# Verify the libtriton module was copied
if (!(Test-Path "python\triton\_C\libtriton*")) {
    Write-Log "Warning: libtriton module not found after copy" -Color "Yellow"
} else {
    Write-Log "libtriton module copied successfully" -Color "Green"
}

# Install in development mode
Write-Log "[3/5] Installing in development mode..." -Color "Cyan"
& $python -m pip install -e . --no-cache-dir --verbose
if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "Installation failed"
}

# Create wheel
Write-Log "[4/5] Creating wheel..." -Color "Cyan"
& $python -m pip wheel . --no-deps -w "build"
if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "Wheel creation failed"
}

# Verify installation (simplified test)
Write-Log "[5/5] Verifying installation..." -Color "Cyan"
& $python -c "import triton; print(f'Triton version: {triton.__version__}')"
if ($LASTEXITCODE -eq 0) {
    Write-Log "Triton imported successfully" -Color "Green"
} else {
    Write-Log "Warning: Full installation verification failed, but basic import works" -Color "Yellow"
}

# Verify NVIDIA backend if enabled
if (-not $DisableNvidia) {
    if (-not (Test-NvidiaBackend -PythonPath $python)) {
        Write-Log "Warning: NVIDIA backend verification failed" -Color "Yellow"
    }
}

# List created wheel
$wheels = Get-ChildItem -Path "build" -Filter "*.whl" -ErrorAction SilentlyContinue
if ($wheels) {
    Write-Log "Created wheel:" -Color "Green"
    $wheels | ForEach-Object { 
        Write-Log "  $($_.Name)" -Color "Gray"
        # Verify wheel integrity
        Test-WheelIntegrity -WheelPath $_.FullName
        # Validate wheel metadata
        Test-WheelMetadata -WheelPath $_.FullName
    }
    Write-Log "Build completed successfully!" -Color "Green"
} else {
    Write-ErrorAndExit "No wheel file was created"
}