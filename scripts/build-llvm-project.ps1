# Build LLVM for Windows
# This script builds LLVM with the required targets for Triton on Windows

param(
    [string]$LLVMTargets = "Native;NVPTX",
    [string]$LLVMProjects = "mlir;llvm",
    [string]$LLVMBuildType = "Release",
    [string]$LLVMCommitHash = "",
    [string]$LLVMProjectPath = "",
    [string]$LLVMInstallPath = ""
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

# ----------------------------------------
# Main Build Process
# ----------------------------------------

Write-Log "Starting LLVM build for Triton Windows..." -Color "Green"

# Set default paths if not provided
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptPath

if (-not $LLVMCommitHash) {
    $hashFile = "$repoRoot\cmake\llvm-hash.txt"
    if (Test-Path $hashFile) {
        $LLVMCommitHash = Get-Content $hashFile | Select-Object -First 1
        Write-Log "Using LLVM commit hash from file: $LLVMCommitHash" -Color "Gray"
    } else {
        Write-ErrorAndExit "LLVM hash file not found: $hashFile"
    }
}

if (-not $LLVMProjectPath) {
    $LLVMProjectPath = "$repoRoot\llvm-project"
}

if (-not $LLVMInstallPath) {
    $LLVMInstallPath = "$LLVMProjectPath\install"
}

$LLVMBuildPath = "$LLVMProjectPath\build"

Write-Log "Configuration:" -Color "Cyan"
Write-Log "  LLVM Targets: $LLVMTargets" -Color "Gray"
Write-Log "  LLVM Projects: $LLVMProjects" -Color "Gray"
Write-Log "  Build Type: $LLVMBuildType" -Color "Gray"
Write-Log "  Commit Hash: $LLVMCommitHash" -Color "Gray"
Write-Log "  Project Path: $LLVMProjectPath" -Color "Gray"
Write-Log "  Build Path: $LLVMBuildPath" -Color "Gray"
Write-Log "  Install Path: $LLVMInstallPath" -Color "Gray"

# Check for required tools
Write-Log "Checking for required tools..." -Color "Cyan"

# Check for Git
try {
    $gitVersion = & git --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Git found: $gitVersion" -Color "Green"
    } else {
        Write-ErrorAndExit "Git not found. Please install Git."
    }
} catch {
    Write-ErrorAndExit "Git not found. Please install Git."
}

# Check for CMake
try {
    $cmakeVersion = & cmake --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "CMake found: $cmakeVersion" -Color "Green"
    } else {
        Write-ErrorAndExit "CMake not found. Please install CMake."
    }
} catch {
    Write-ErrorAndExit "CMake not found. Please install CMake."
}

# Check for Ninja
try {
    $ninjaVersion = & ninja --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Ninja found: $ninjaVersion" -Color "Green"
    } else {
        Write-Log "Warning: Ninja not found. Will use Visual Studio generator." -Color "Yellow"
        $useNinja = $false
    }
} catch {
    Write-Log "Warning: Ninja not found. Will use Visual Studio generator." -Color "Yellow"
    $useNinja = $false
}

# Check for Visual Studio (required if not using Ninja)
if (-not $useNinja) {
    $vs = Get-ChildItem "C:\Program Files\Microsoft Visual Studio\2022" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($vs) {
        Write-Log "Visual Studio found: $($vs.FullName)" -Color "Green"
    } else {
        Write-ErrorAndExit "Visual Studio 2022 not found. Please install Visual Studio 2022."
    }
}

# Clone or update LLVM project
if (-not (Test-Path $LLVMProjectPath)) {
    Write-Log "Cloning LLVM project..." -Color "Cyan"
    & git clone "https://github.com/llvm/llvm-project" $LLVMProjectPath
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorAndExit "Failed to clone LLVM project"
    }
} else {
    Write-Log "LLVM project directory already exists" -Color "Gray"
}

# Reset to the specific commit hash
Write-Log "Resetting to commit hash: $LLVMCommitHash" -Color "Cyan"
Set-Location $LLVMProjectPath
& git fetch origin $LLVMCommitHash
if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "Failed to fetch commit $LLVMCommitHash"
}

& git reset --hard $LLVMCommitHash
if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "Failed to reset to commit $LLVMCommitHash"
}

# Configure with CMake
Write-Log "Configuring with CMake..." -Color "Cyan"
$cmakeArgs = @(
    "-DCMAKE_BUILD_TYPE=$LLVMBuildType"
    "-DLLVM_ENABLE_ASSERTIONS=ON"
    "-DLLVM_ENABLE_LLD=OFF"  # LLD may not work well on Windows
    "-DLLVM_OPTIMIZED_TABLEGEN=ON"
    "-DLLVM_TARGETS_TO_BUILD=$LLVMTargets"
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
    "-DLLVM_ENABLE_PROJECTS=$LLVMProjects"
    "-DCMAKE_INSTALL_PREFIX=$LLVMInstallPath"
)

# Add generator
if ($useNinja) {
    $cmakeArgs += "-G Ninja"
} else {
    $cmakeArgs += "-G", "Visual Studio 17 2022"
}

$cmakeArgs += "-B$LLVMBuildPath"
$cmakeArgs += "$LLVMProjectPath\llvm"

Write-Log "CMake arguments: $($cmakeArgs -join ' ')" -Color "Gray"
& cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "CMake configuration failed"
}

# Build LLVM
Write-Log "Building LLVM (this will take a long time)..." -Color "Cyan"
if ($useNinja) {
    & ninja -C $LLVMBuildPath
} else {
    & cmake --build $LLVMBuildPath --config $LLVMBuildType --target ALL_BUILD
}

if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "LLVM build failed"
}

# Install LLVM
Write-Log "Installing LLVM..." -Color "Cyan"
if ($useNinja) {
    & cmake --build $LLVMBuildPath --target install
} else {
    & cmake --build $LLVMBuildPath --config $LLVMBuildType --target INSTALL
}

if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "LLVM installation failed"
}

Write-Log "LLVM build completed successfully!" -Color "Green"
Write-Log "Installed to: $LLVMInstallPath" -Color "Gray"