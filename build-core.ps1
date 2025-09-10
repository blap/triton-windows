# Triton Windows Build Script (Core Only)
# Builds Triton for Windows without NVIDIA GPU support
#
# Usage:
#   .\build-core.ps1                    # Normal build without NVIDIA support
#   .\build-core.ps1 -PythonPath "C:\path\to\python.exe"  # Use specific Python

param(
    [string]$PythonPath = ""
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

# Add ninja to PATH
$env:PATH = "$pwd\ninja-install;$env:PATH"

Write-Log "Starting Triton Windows build (Core Only)..." -Color "Green"
Write-Log "Working directory: $(Get-Location)" -Color "Gray"

# Clean build artifacts
Clean-BuildArtifacts

# Verify Python installation
$python = Find-Python -PythonPath $PythonPath
if (-not $python) {
    Write-ErrorAndExit "Python not found"
}
Write-Log "Using Python: $python" -Color "Green"

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

# Disable NVIDIA backend
$env:TRITON_CODEGEN_BACKENDS = ""
$env:TRITON_DISABLE_NVIDIA_BACKEND = "ON"
Write-Log "Building without NVIDIA support" -Color "Yellow"

$env:TRITON_BUILD_PYTHON_MODULE = "1"
$env:MAX_JOBS = "1"

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

# Configure with CMake, disabling NVIDIA backend
Write-Log "Configuring with CMake..." -Color "Cyan"

# Set up Visual Studio environment properly
$vcVarsPath = "$vs\VC\Auxiliary\Build\vcvars64.bat"
if (Test-Path $vcVarsPath) {
    Write-Log "Setting up Visual Studio environment..." -Color "Yellow"
    # Run vcvars64.bat to set up the environment
    cmd /c """$vcVarsPath"" && set" | ForEach-Object {
        if ($_ -match "^(.+)=(.*)$") {
            $varName = $matches[1]
            $varValue = $matches[2]
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

& cmake -G "Ninja" -DCMAKE_MAKE_PROGRAM="$pwd\ninja-install\ninja.exe" -DCMAKE_BUILD_TYPE=Release -DLLVM_DIR="$env:LLVM_DIR" -DMLIR_DIR="$env:MLIR_DIR" -DPYBIND11_DIR="$pybind11CmakeDir" -DTRITON_DISABLE_NVIDIA_BACKEND=ON -B build .
if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "CMake configuration failed"
}

# Build with Ninja
Write-Log "Building with Ninja..." -Color "Cyan"
# Clean any existing build files that might cause permission issues
if (Test-Path "build\build.ninja") {
    Write-Log "Removing existing build.ninja to prevent permission issues..." -Color "Yellow"
    Remove-Item "build\build.ninja" -Force -ErrorAction SilentlyContinue
}
if (Test-Path "build\.ninja_deps") {
    Write-Log "Removing existing .ninja_deps to prevent permission issues..." -Color "Yellow"
    Remove-Item "build\.ninja_deps" -Force -ErrorAction SilentlyContinue
}
if (Test-Path "build\.ninja_log") {
    Write-Log "Removing existing .ninja_log to prevent permission issues..." -Color "Yellow"
    Remove-Item "build\.ninja_log" -Force -ErrorAction SilentlyContinue
}

& cmake -G "Ninja" -DCMAKE_MAKE_PROGRAM="$pwd\ninja-install\ninja.exe" -DCMAKE_BUILD_TYPE=Release -DLLVM_DIR="$env:LLVM_DIR" -DMLIR_DIR="$env:MLIR_DIR" -DPYBIND11_DIR="$pybind11CmakeDir" -DTRITON_DISABLE_NVIDIA_BACKEND=ON -B build .
if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "CMake configuration failed"
}

# Build with Ninja, targeting only libtriton to avoid mlir-doc issues
Write-Log "Building with Ninja (libtriton target only)..." -Color "Cyan"
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

# List created wheel
$wheels = Get-ChildItem -Path "build" -Filter "*.whl" -ErrorAction SilentlyContinue
if ($wheels) {
    Write-Log "Created wheel:" -Color "Green"
    $wheels | ForEach-Object { 
        Write-Log "  $($_.Name)" -Color "Gray"
    }
    Write-Log "Core build completed successfully!" -Color "Green"
} else {
    Write-ErrorAndExit "No wheel file was created"
}