# Check available versions for NVIDIA toolchain components
Write-Host "Checking available versions for NVIDIA toolchain components..." -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Green

# Components to check
$components = @(
    @{name="cuda_nvcc"; displayName="ptxas"},
    @{name="cuda_cuobjdump"; displayName="cuobjdump"},
    @{name="cuda_nvdisasm"; displayName="nvdisasm"},
    @{name="cuda_cudart"; displayName="cudart"},
    @{name="cuda_cupti"; displayName="cupti"}
)

$platform = "windows-x86_64"

foreach ($component in $components) {
    $url = "https://developer.download.nvidia.com/compute/cuda/redist/$($component.name)/$platform/"
    Write-Host "Checking $($component.displayName) ($($component.name))..." -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
        $content = $response.Content
        
        # Extract version numbers that match 12.9.x pattern
        $versions = $content | Select-String -Pattern "$($component.name)-$platform-(12\.9\.[0-9]+)-archive\.zip" -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value }
        
        if ($versions) {
            Write-Host "  Available versions: $($versions -join ', ')" -ForegroundColor Green
        } else {
            Write-Host "  No 12.9.x versions found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Error checking versions: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Special case for cudacrt which uses cuda_nvcc
Write-Host "Checking cudacrt (uses cuda_nvcc)..." -ForegroundColor Cyan
try {
    $url = "https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/$platform/"
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    $content = $response.Content
    
    # Extract version numbers that match 12.9.x pattern
    $versions = $content | Select-String -Pattern "cuda_nvcc-$platform-(12\.9\.[0-9]+)-archive\.zip" -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value }
    
    if ($versions) {
        Write-Host "  Available versions: $($versions -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "  No 12.9.x versions found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Error checking versions: $($_.Exception.Message)" -ForegroundColor Red
}