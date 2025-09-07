# Triton Windows Build Script
# Builds Triton for Windows with NVIDIA GPU support
#
# Usage:
#   .\build.ps1                    # Normal build with NVIDIA support
#   .\build.ps1 -DisableNvidia     # Build without NVIDIA support
#   .\build.ps1 -PythonPath "C:\path\to\python.exe"  # Use specific Python

param(
    [switch]$DisableNvidia,
    [string]$PythonPath = ""
)

# ----------------------------------------
# Utility Functions
# ----------------------------------------

function Find-Python {
    param([string]$PythonPath)
    
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
        if (Test-Path $path) { return $path }
    }
    
    # Try PATH
    try {
        $path = (Get-Command python -ErrorAction SilentlyContinue).Source
        if ($path -and (Test-Path $path)) { return $path }
    } catch {}
    
    return $null
}

function Find-VisualStudio {
    $paths = @(
        "C:\Program Files\Microsoft Visual Studio\2022\Community",
        "C:\Program Files\Microsoft Visual Studio\2022\Professional",
        "C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

# Fix f2reduce version file to prevent C++ compilation errors
function Fix-F2ReduceVersion {
    $file = "third_party\f2reduce\version"
    if (Test-Path $file) {
        $content = "// f2reduce version information`n// File intentionally empty to prevent C++ compilation issues"
        Set-Content -Path $file -Value $content -Encoding UTF8
    }
}

# ----------------------------------------
# Main Build Process
# ----------------------------------------

Write-Host "Starting Triton Windows build..." -ForegroundColor Green

# Verify Python installation
$python = Find-Python -PythonPath $PythonPath
if (-not $python) {
    Write-Host "Error: Python not found" -ForegroundColor Red
    exit 1
}
Write-Host "Using Python: $python" -ForegroundColor Green

# Verify Visual Studio installation
$vs = Find-VisualStudio
if (-not $vs) {
    Write-Host "Error: Visual Studio 2022 not found" -ForegroundColor Red
    exit 1
}
Write-Host "Using Visual Studio: $vs" -ForegroundColor Green

# Configure MSVC
$msvc = Get-ChildItem "$vs\VC\Tools\MSVC" | Sort-Object Name -Descending | Select-Object -First 1
if (-not $msvc) {
    Write-Host "Error: MSVC tools not found" -ForegroundColor Red
    exit 1
}
$msvcVersion = $msvc.Name
Write-Host "Using MSVC: $msvcVersion" -ForegroundColor Green

# Configure environment
$env:CC = "$vs\VC\Tools\MSVC\$msvcVersion\bin\Hostx64\x64\cl.exe"
$env:CXX = "$vs\VC\Tools\MSVC\$msvcVersion\bin\Hostx64\x64\cl.exe"

# Fix f2reduce version file before build
Fix-F2ReduceVersion

# Ensure pybind11 3.0.1 is installed
try {
    & $python -c "import pybind11; version=pybind11.__version__" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Installing pybind11==3.0.1..." -ForegroundColor Yellow
        & $python -m pip install pybind11==3.0.1
    } else {
        $version = & $python -c "import pybind11; print(pybind11.__version__)"
        if ($version -ne "3.0.1") {
            Write-Host "Updating pybind11 to 3.0.1..." -ForegroundColor Yellow
            & $python -m pip install pybind11==3.0.1 --force-reinstall
        }
    }
} catch {
    Write-Host "Error: Failed to configure pybind11" -ForegroundColor Red
    exit 1
}

# Configure build options
if ($DisableNvidia) {
    $env:TRITON_CODEGEN_BACKENDS = ""
    Write-Host "Building without NVIDIA support" -ForegroundColor Yellow
} else {
    $env:TRITON_CODEGEN_BACKENDS = "nvidia"
    Write-Host "Building with NVIDIA support" -ForegroundColor Green
}

$env:TRITON_BUILD_PYTHON_MODULE = "1"
$env:MAX_JOBS = "1"

# Clean previous builds
Write-Host "Cleaning build cache..." -ForegroundColor Cyan
Get-ChildItem -Path "." -Recurse -Name "__pycache__" -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path "build") { Remove-Item "build\*" -Recurse -Force -ErrorAction SilentlyContinue }

# Build Triton
Write-Host "Building Triton..." -ForegroundColor Cyan
& $python -m pip install -e . --no-cache-dir --verbose
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed" -ForegroundColor Red
    exit 1
}

# Create wheel
Write-Host "Creating wheel..." -ForegroundColor Cyan
if (!(Test-Path "build")) { New-Item -ItemType Directory -Path "build" | Out-Null }
& $python -m pip wheel . --no-deps -w "build"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Wheel creation failed" -ForegroundColor Red
    exit 1
}

# Verify installation
Write-Host "Verifying installation..." -ForegroundColor Cyan
& $python -c "import triton; print(f'Triton {triton.__version__} imported successfully')"
if ($LASTEXITCODE -eq 0) {
    Write-Host "Build completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Installation verification failed" -ForegroundColor Red
    exit 1
}

# List created wheel
$wheels = Get-ChildItem -Path "build" -Filter "*.whl" -ErrorAction SilentlyContinue
if ($wheels) {
    Write-Host "Created wheel:" -ForegroundColor Green
    $wheels | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }
}
