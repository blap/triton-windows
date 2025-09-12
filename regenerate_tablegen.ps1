# Script to regenerate TableGen files for NVGPU dialect
# This script properly generates the required enum files to avoid conflicts

# Ensure we're in the correct directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $scriptPath

Write-Host "Starting TableGen regeneration..." -ForegroundColor Green

# Set LLVM path
$llvmPath = "C:\Users\Admin\.triton\llvm\llvm-8957e64a-windows-x64"
if (!(Test-Path $llvmPath)) {
    Write-Host "ERROR: LLVM not found at $llvmPath" -ForegroundColor Red
    exit 1
}

# Add LLVM bin to PATH
$env:PATH = "$llvmPath\bin;$env:PATH"

# Find mlir-tblgen
$mlirTblgen = Join-Path $llvmPath "bin\mlir-tblgen.exe"
if (!(Test-Path $mlirTblgen)) {
    Write-Host "ERROR: mlir-tblgen not found at $mlirTblgen" -ForegroundColor Red
    exit 1
}

Write-Host "Using mlir-tblgen: $mlirTblgen" -ForegroundColor Gray

# Function to regenerate files for a specific directory
function Regenerate-TableGenFiles {
    param(
        [string]$Directory,
        [string]$DialectName
    )
    
    Write-Host "Regenerating TableGen files for $Directory..." -ForegroundColor Cyan
    
    # Change to the directory
    $currentDir = Get-Location
    Set-Location $Directory
    
    # Include paths
    $includePaths = @(
        "../../../..",
        "../../../../../../../build/include",
        "$scriptPath/include",
        "$scriptPath/build/include"
    )
    
    # TableGen commands
    $commands = @(
        "Dialect.h.inc -gen-dialect-decls -dialect=$DialectName",
        "Dialect.cpp.inc -gen-dialect-defs -dialect=$DialectName",
        "OpsConversions.inc -gen-llvmir-conversions",
        "OpsEnums.h.inc -gen-enum-decls",
        "OpsEnums.cpp.inc -gen-enum-defs",
        "Ops.h.inc -gen-op-decls",
        "Ops.cpp.inc -gen-op-defs"
    )
    
    foreach ($cmdPart in $commands) {
        $fullCmd = "& `"$mlirTblgen`" $cmdPart"
        foreach ($includePath in $includePaths) {
            $fullCmd += " -I$includePath"
        }
        
        Write-Host "Running: $fullCmd" -ForegroundColor Gray
        Invoke-Expression $fullCmd
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Warning: Command failed: $fullCmd" -ForegroundColor Yellow
        }
    }
    
    # Return to original directory
    Set-Location $currentDir
}

# Regenerate NVGPU dialect files
$nvgpuDir = Join-Path $scriptPath "third_party\nvidia\include\Dialect\NVGPU\IR"
if (Test-Path $nvgpuDir) {
    Regenerate-TableGenFiles -Directory $nvgpuDir -DialectName "nvgpu"
} else {
    Write-Host "Warning: NVGPU directory not found: $nvgpuDir" -ForegroundColor Yellow
}

# Regenerate main Triton dialect files
$tritonDir = Join-Path $scriptPath "include\triton\Dialect\Triton\IR"
if (Test-Path $tritonDir) {
    Regenerate-TableGenFiles -Directory $tritonDir -DialectName "triton"
} else {
    Write-Host "Warning: Triton directory not found: $tritonDir" -ForegroundColor Yellow
}

# Regenerate TritonGPU dialect files
$tritonGpuDir = Join-Path $scriptPath "include\triton\Dialect\TritonGPU\IR"
if (Test-Path $tritonGpuDir) {
    Regenerate-TableGenFiles -Directory $tritonGpuDir -DialectName "tritongpu"
} else {
    Write-Host "Warning: TritonGPU directory not found: $tritonGpuDir" -ForegroundColor Yellow
}

Write-Host "TableGen regeneration completed!" -ForegroundColor Green